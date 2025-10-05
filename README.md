# ConditionalAccessManager

<p align="center">
  <a href="https://www.linkedin.com/in/michaelmsonne/"><img alt="Made by" src="https://img.shields.io/static/v1?label=made%20by&message=Michael%20Morten%20Sonne&color=04D361"></a>
  <a href="https://github.com/michaelmsonne/ConditionalAccessManager"><img src="https://img.shields.io/github/languages/top/ConditionalAccessManager/ConditionalAccessManager.svg"></a>
  <a href="https://github.com/michaelmsonne/ConditionalAccessManager"><img src="https://img.shields.io/github/languages/code-size/ConditionalAccessManager/ConditionalAccessManager.svg"></a>
  <img src="https://visitor-badge.laobi.icu/badge?page_id=michaelmsonne.ConditionalAccessManager.README" alt="Visitors">
  <img src="https://img.shields.io/badge/PowerShell-5.1%2B-blue" alt="PowerShell"></a>
  <img src="https://img.shields.io/badge/Platform-Windows-0078D7" alt="Platform"></a>
  <a href="https://github.com/michaelmsonne/ConditionalAccessManager/blob/main/LICENSE.md"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
  <a href="https://github.com/michaelmsonne/ConditionalAccessManager"><img src="https://img.shields.io/github/downloads/michaelmsonne/ConditionalAccessManager/total.svg"></a><br>
  <a href="https://www.buymeacoffee.com/sonnes" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 30px !important;width: 117px !important;"></a>
  
</p>

[//]: #https://img.shields.io/badge/C%23-239120
[//]: #https://img.shields.io/badge/PowerShell-5.1%2B-blue

<div align="center">
  <a href="https://github.com/michaelmsonne/ConditionalAccessManager/issues/new?assignees=&labels=bug&ConditionalAccessManager=01_BUG_REPORT.md&title=bug%3A+">Report a Bug</a>
  ·
  <a href="https://github.com/michaelmsonne/ConditionalAccessManager/issues/new?assignees=&labels=enhancement&ConditionalAccessManager=02_FEATURE_REQUEST.md&title=feat%3A+">Request a Feature</a>
  .
  <a href="https://github.com/michaelmsonne/ConditionalAccessManager/discussions">Ask a Question</a>
</div>

<div align="center">
<br />

</div>

## Table of Contents
- [Introduction](#introduction)
- [Contents](#contents)
- [Features](#features)
- [Download](#download)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
- [Examples](#examples)
- [Contributing](#contributing)
- [Status](#status)
- [Support](#support)
- [License](#license)
- [Credits](#credit)

# Introduction
A PowerShell module for managing deleted Conditional Access policies in Microsoft Entra ID using Microsoft Graph API.

## Contents

Outline the file contents of the repository. It helps users navigate the codebase, build configuration and any related assets.

| File/folder       | Description                                 |
|-------------------|---------------------------------------------|
| `src`             | Source code.                                |
| `.gitignore`      | Define what to ignore at commit time.       |
| `CHANGELOG.md`    | List of changes to the sample.              |
| `CONTRIBUTING.md` | Guidelines for contributing to the ConditionalAccessManager.|
| `README.md`       | This README file.                           |
| `SECURITY.md`     | This README file.                           |
| `LICENSE`         | The license for the ConditionalAccessManager.               |

## 🚀 Features

- **List deleted policies** - View all deleted Conditional Access policies with clean formatting
- **Restore policies** - Restore deleted policies back to enabled state with confirmation
- **Permanently remove policies** - Clean up deleted policies permanently with safety prompts
- **Advanced export** - Export policies to individual JSON files with state filtering
  - Export enabled policies only
  - Export disabled policies only
  - Export deleted policies with special naming
  - Organize exports in folders with summary files
- **Retry logic** - Built-in 429 throttling and error handling with exponential backoff
- **Interactive console** - Enhanced menu-driven interface with better formatting
- **Automatic authentication** - Smart connection management with scope validation


## Download

[Download the latest version](../../releases/latest)

[Version History](CHANGELOG.md)

## Prerequisites

- PowerShell 5.1 or higher
- Microsoft.Graph PowerShell module
- Appropriate permissions in Microsoft Entra ID:
  - `Policy.Read.All` (to read policies)
  - `Policy.ReadWrite.ConditionalAccess` (to restore/delete policies)

## Installation

1. Clone or download the module to your PowerShell modules directory
2. Import the module:

```powershell
Import-Module .\ConditionalAccessManager
```

3. Connect to Microsoft Graph:

```powershell
Connect-MgGraph -Scopes "Policy.Read.All", "Policy.ReadWrite.ConditionalAccess"
```

## Usage

### Interactive Console

Start the interactive menu-driven console:

```powershell
Start-ConditionalAccessManagerConsole
```

### Individual Commands

```powershell
# List deleted policies (clean table format)
Get-DeletedConditionalAccessPolicies

# List with full details
Get-DeletedConditionalAccessPolicies -IncludeDetails

# Restore a specific policy
Restore-ConditionalAccessPolicy -PolicyId "12345678-1234-1234-1234-123456789012"

# Permanently remove a deleted policy
Remove-DeletedConditionalAccessPolicy -PolicyId "12345678-1234-1234-1234-123456789012" -Force

# Export to individual JSON files with state filtering
Export-ConditionalAccessPolicies -OutputFolder "C:\backup\ca-policies" -IncludeEnabled -IncludeDisabled -IncludeDeleted

# Start the interactive console
Start-ConditionalAccessManagerConsole
```

## Examples

### Basic Policy Recovery

```powershell
# Connect to Graph
Connect-MgGraph

# List deleted policies
$deletedPolicies = Get-DeletedConditionalAccessPolicies
$deletedPolicies | Format-Table

# Restore the first policy
if ($deletedPolicies.Count -gt 0) {
    Restore-ConditionalAccessPolicy -PolicyId $deletedPolicies[0].id
}
```

### Bulk Operations

```powershell
# Get all deleted policies and restore them
Get-DeletedConditionalAccessPolicies | ForEach-Object {
    Write-Host "Restoring: $($_.displayName)"
    Restore-ConditionalAccessPolicy -PolicyId $_.id
}
```

### Export and Backup

```powershell
# Create comprehensive backup with individual files
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
Export-ConditionalAccessPolicies -OutputFolder ".\CA-Backup-$timestamp" -IncludeEnabled -IncludeDisabled -IncludeDeleted

# Export only production policies (enabled)
Export-ConditionalAccessPolicies -OutputFolder ".\Production-Policies-$timestamp" -IncludeEnabled

# Export deleted policies for audit
Export-ConditionalAccessPolicies -OutputFolder ".\Deleted-Audit-$timestamp" -IncludeDeleted
```

# 📸 Screenshots

# Main menu

![Screenshot](docs/pictures/help-menu.png)

## Export File Organization

The module creates well-organized exports for easy management:

### File Structure
```
CA-Policies-Export-20251005-123456/
├── _ExportSummary.json                            # Export metadata and counts
├── Policy_Name_Here_12345678-abcd-efgh.json       # Enabled policies
├── Another_Policy_87654321-wxyz-1234.json         # Enabled policies  
├── DELETED_Test_Policy_11111111-dddd-eeee.json    # Deleted policies (prefixed)
└── ...
```

### File Naming Convention
- **Enabled/Disabled policies**: `PolicyName_PolicyID.json`
- **Deleted policies**: `DELETED_PolicyName_PolicyID.json`
- **Special characters**: Automatically sanitized for filesystem compatibility
- **Summary file**: `_ExportSummary.json` with export statistics

### File Contents
Each policy file contains:
- Export timestamp
- Policy type (Enabled/Disabled/Deleted)
- Complete policy configuration
- All conditions, grant controls, and session controls

## Error Handling

The module includes comprehensive error handling and resilience:

- **Authentication errors** - Clear messages when not connected to Graph with automatic connection prompts
- **Permission errors** - Specific guidance on required scopes with validation
- **API throttling** - Built-in retry logic for 429 "Too Many Requests" with exponential backoff
- **Rate limiting** - Respects Retry-After headers and implements jitter for optimal performance
- **API errors** - Detailed error messages from Graph API with context (to-do)
- **Validation** - Input validation for policy IDs, file paths, and folder structures
- **Resilient exports** - Individual file failures don't stop entire export process

## Security Considerations

- Always use least-privilege permissions
- Regularly audit restored policies
- Keep backups of policy configurations
- Test in non-production environments first
- Review exported files before sharing (may contain sensitive configuration data)
- Use secure storage for exported policy files

# Contributing
If you want to contribute to this project, please open an issue or submit a pull request. I welcome contributions :)

See [CONTRIBUTING](CONTRIBUTING) for more information.

First off, thanks for taking the time to contribute! Contributions are what makes the open-source community such an amazing place to learn, inspire, and create. Any contributions you make will benefit everybody else and are **greatly appreciated**.
Feel free to send pull requests or fill out issues when you encounter them. I'm also completely open to adding direct maintainers/contributors and working together! :)

Please try to create bug reports that are:

- _Reproducible._ Include steps to reproduce the problem.
- _Specific._ Include as much detail as possible: which version, what environment, etc.
- _Unique._ Do not duplicate existing opened issues.
- _Scoped to a Single Bug._ One bug per report.´´

# Status

The project is actively developed and updated.

# Support

Commercial support

This project is open-source and I invite everybody who can and will to contribute, but I cannot provide any support because I only created this as a "hobby project" ofc. with tbe best in mind. For commercial support, please contact me on LinkedIn so we can discuss the possibilities. It’s my choice to work on this project in my spare time, so if you have commercial gain from this project you should considering sponsoring me.

<a href="https://www.buymeacoffee.com/sonnes" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 30px !important;width: 117px !important;"></a>

Thanks.

Reach out to the maintainer at one of the following places:

- [GitHub discussions](https://github.com/michaelmsonne/ConditionalAccessManager/discussions)
- The email which is located [in GitHub profile](https://github.com/michaelmsonne)

# 📄 License
This project is licensed under the **MIT License** - see the LICENSE file for details.

See [LICENSE](LICENSE) for more information.

# 🙏 Credits