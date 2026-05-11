<<<<<<< HEAD
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
=======
---
name: Bug report
about: Something isn't working right.
title: ''
labels: bug, to check
assignees: ''

---

**Prerequisites**
<!-- Please ensure your request is not part of an existing issue. -->
<!-- Please ensure you have checked the Obtainium Wiki. -->
<!-- Please ensure your request is an actual bug and not intended behaviour (this is frequently the case for issues involving version strings and the HTML source. -->

**Describe the bug**
<!-- A clear and concise description of what the bug is. -->

**To Reproduce**
<!-- Steps to reproduce the behavior:
1. Go to '...'
2. Tap on '....'
3. Scroll down to '....'
4. See error -->

**Screenshots and Logs**
<!-- If applicable, add screenshots, logs, and any other artifacts (like some/all files under `/Android/data/dev.imranr.obtainium/`) that you think may help troubleshoot the issue. -->

**Please complete the following information:**
 - Device: <!-- [e.g. Pixel 7] -->
 - OS: <!-- [e.g. GrapheneOS] -->
 - Obtainium Version: <!-- [e.g. 0.14.6-beta] -->

**Additional context**
<!-- Add any other context about the problem here. -->
>>>>>>> upstream/main
