name: Crash Report
description: Report a crash or a major error in Obtainium+
title: "[CRASH]: "
labels: ["bug", "crash"]
assignees: []
body:
  - type: markdown
    attributes:
      value: |
        Thank you for reporting this crash! Please provide as much information as possible to help us fix it.
  - type: textarea
    id: description
    attributes:
      label: Description
      description: What were you doing when the crash occurred?
      placeholder: I was clicking on the 'Update' button...
    validations:
      required: true
  - type: textarea
    id: logs
    attributes:
      label: Crash Logs / Stack Trace
      description: Please paste any error messages or stack traces you saw (from the Error Screen or Sentry).
      render: shell
    validations:
      required: true
  - type: input
    id: version
    attributes:
      label: App Version
      placeholder: e.g., 1.2.9-p75
    validations:
      required: true
  - type: input
    id: device
    attributes:
      label: Device Info
      placeholder: e.g., Pixel 7, Android 14
    validations:
      required: true
  - type: checkboxes
    id: terms
    attributes:
      label: Confirmation
      options:
        - label: I have checked that this issue isn't already reported.
          required: true
