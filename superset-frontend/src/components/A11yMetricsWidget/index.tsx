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

interface MetricItem {
  label: string;
  value: number;
  icon: string;
}

const metrics: MetricItem[] = [
  { label: 'Open issues', value: 3, icon: '/static/assets/images/alert.svg' },
  { label: 'Resolved', value: 8, icon: '/static/assets/images/check.svg' },
  {
    label: 'Regressions',
    value: 2,
    icon: '/static/assets/images/warning.svg',
  },
];

export default function A11yMetricsWidget() {
  return (
    <div className="a11y-metrics-widget">
      <h2>Accessibility Compliance</h2>

      <div className="metrics-row">
        {metrics.map(metric => (
          <div key={metric.label} className="metric-card">
            <img src={metric.icon} />
            <span className="metric-value">{metric.value}</span>
            <span className="metric-label">{metric.label}</span>
          </div>
        ))}
      </div>

      <div className="widget-actions">
        <button onClick={() => window.location.reload()}>
          <svg viewBox="0 0 24 24" width="16" height="16">
            <path d="M17.65 6.35A7.96 7.96 0 0012 4a8 8 0 108 8h-2a6 6 0 11-6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z" />
          </svg>
        </button>
      </div>
    </div>
  );
}
