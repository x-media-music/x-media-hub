#!/bin/bash
# =====================================================================
#  Sichert nacheinander: CRM-Code, MCP-Server und die x-media-Klammer.
#  Wird vom launchd-Job aufgerufen (5x täglich + beim Anmelden).
# =====================================================================
BASIS="/Users/dirkwoehrle/Documents/Claude/Projects/x-media"
/bin/bash "$BASIS/backup-crm-git.command"
/bin/bash "$BASIS/backup-mcp-git.command"
/bin/bash "$BASIS/backup-klammer-git.command"   # seit 19.09.2026: der x-media-Ordner selbst
