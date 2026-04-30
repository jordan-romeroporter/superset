/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

import React from 'react';

interface UserProfile {
  name: string;
  email: string;
  avatar: string;
  role: string;
}

interface UserProfileCardProps {
  user: UserProfile;
  onEdit: () => void;
  onDelete: () => void;
}

export default function UserProfileCard({
  user,
  onEdit,
  onDelete,
}: UserProfileCardProps) {
  return (
    <div className="user-profile-card">
      <img src={user.avatar} />

      <div className="user-info">
        <h3>{user.name}</h3>
        <p>{user.email}</p>
        <span className="role-badge">{user.role}</span>
      </div>

      <div className="card-actions">
        <div onClick={onEdit} className="action-icon">
          <svg viewBox="0 0 24 24" width="18" height="18">
            <path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04a1 1 0 000-1.41l-2.34-2.34a1 1 0 00-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z" />
          </svg>
        </div>

        <div onClick={onDelete} className="action-icon">
          <svg viewBox="0 0 24 24" width="18" height="18">
            <path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z" />
          </svg>
        </div>
      </div>
    </div>
  );
}
