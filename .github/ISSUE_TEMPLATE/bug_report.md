name: Bug Report
description: Report a bug to help improve Obtainium+
labels: ["bug", "triage"]
body:
  - type: markdown
    attributes:
      value: |
        ### Thank you for reporting a bug! 
        Please provide as much detail as possible. If you have diagnostic logs, please include them in the section below.
  - type: textarea
    id: description
    attributes:
      label: Description
      description: A clear and concise description of what the bug is.
      placeholder: I was trying to... and then...
    validations:
      required: true
  - type: textarea
    id: steps
    attributes:
      label: Steps to Reproduce
      description: How did you encounter this bug?
      placeholder: |
        1. Go to '...'
        2. Click on '....'
        3. Scroll down to '....'
        4. See error
    validations:
      required: true
  - type: input
    id: version
    attributes:
      label: Obtainium+ Version
      description: You can find this in Settings > About.
      placeholder: e.g., 1.2.9-p90
    validations:
      required: true
  - type: textarea
    id: logs
    attributes:
      label: Diagnostic Logs
      description: |
        If you used the **"Upload Logs to New Issue"** feature in Developer Options, the logs should already be here. 
        Otherwise, please paste them below.
      placeholder: Paste logs from Developer Options > View Talker Logs here.
  - type: checkboxes
    id: context
    attributes:
      label: Context
      options:
        - label: This issue occurs consistently.
        - label: I have checked Sentry and it matches a known crash.
