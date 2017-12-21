import React from 'react';
import PropTypes from 'prop-types';
import List from '../common/list.jsx';
import AdminUser from './admin_user.jsx';

const AdminUserList = ({ adminUsers, sortBy }) => {
  const elements = adminUsers.map(user => {
    return <AdminUser user={user} key={user.id} />;
  });

  const keys = {

    username: {
      label: 'User Name',
      desktop_only: false,
    },
    real_name: {
      label: 'Real Name',
      desktop_only: true
    },
    admin_level: {
      label: 'Admin Level',
      desktop_only: false
    },
  };

  return (
    <div>
      <List
        elements={elements}
        keys={keys}
        table_key="admin-users"
        none_message={'no admin users'}
        sortBy={sortBy}
      />

    </div>
  );
};

AdminUserList.propTypes = {
  adminUsers: PropTypes.array,
};

export default AdminUserList;
