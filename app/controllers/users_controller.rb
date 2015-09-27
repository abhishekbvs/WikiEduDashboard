require "#{Rails.root}/lib/wiki_edits"

#= Controller for user functionality
class UsersController < ApplicationController
  respond_to :html, :json

  def signout
    if current_user.nil?
      redirect_to '/'
    else
      current_user.update_attributes(wiki_token: nil, wiki_secret: nil)
      redirect_to true_destroy_user_session_path
    end
  end

  def update_util(model, object)
    if object['id'].nil?
      model.create object
    elsif object['deleted']
      model.destroy object['id']
    else
      model.update object['id'], object
    end
  end

  def save
    @course = Course.find_by_slug(params[:course_id])
    user_params['users'].each do |student|
      if student['deleted']
        s_assignments = @course.assignments.select do |a|
          a.user_id == student['id']
        end
        s_assignments.to_json!
        WikiEdits.update_assignments current_user, @course, s_assignments, true
      end
      update_util User, student
    end

    WikiEdits.update_assignments current_user, @course,
                                 user_params['assignments']

    user_params['assignments'].each do |assignment|
      assignment['course_id'] = @course.id
      assignment['article_title'].gsub!(' ', '_')
      assigned = Article.find_by(title: assignment['article_title'])
      assignment['article_id'] = assigned.id unless assigned.nil?
      update_util Assignment, assignment
    end

    WikiEdits.update_course(@course, current_user)
    render 'users', formats: :json
  end

  #########################
  # Enrollment management #
  #########################
  def enroll
    if request.post?
      add
    elsif request.delete?
      remove
    end
  end

  def enroll_params
    params.require(:user).permit(:user_id, :wiki_id, :role)
  end

  def fetch_enroll_records
    require "#{Rails.root}/lib/importers/user_importer"

    @course = Course.find_by_slug(params[:id])
    if enroll_params.key? :user_id
      @user = User.find(enroll_params[:user_id])
    elsif enroll_params.key? :wiki_id
      wiki_id = enroll_params[:wiki_id]
      @user = User.find_by(wiki_id: wiki_id)
      @user = UserImporter.new_from_wiki_id(wiki_id) if @user.nil?
    else
      return
    end
  end

  def add
    fetch_enroll_records
    if !@user.nil?
      CoursesUsers.create(
        user: @user,
        course_id: @course.id,
        role: enroll_params[:role]
      )

      WikiEdits.update_course(@course, current_user)
      render 'users', formats: :json
    else
      username = enroll_params[:user_id] || enroll_params[:wiki_id]
      render json: { message: I18n.t('courses.error.user_exists',
                                     username: username) },
             status: 404
    end
  end

  def remove
    fetch_enroll_records
    return if @user.nil?

    cu = CoursesUsers.find_by(
      user_id: @user.id,
      course_id: @course.id,
      role: enroll_params[:role]
    )
    return if cu.nil? # This will happen if the user was already removed.
    WikiEdits.update_assignments current_user, @course,
                                 cu.assignments.as_json, true
    cu.destroy

    render 'users', formats: :json
    WikiEdits.update_course(@course, current_user)
  end

  private

  def user_params
    params.permit(
      users: [:id, :wiki_id, :deleted, :email],
      assignments: [:id, :user_id, :article_title, :role, :course_id, :deleted]
    )
  end
end
