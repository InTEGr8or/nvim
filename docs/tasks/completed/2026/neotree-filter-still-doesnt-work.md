# NeoTree / filter still doesn't work

I would expect the filter to filter out any file names that don't match the pattern.

So, if I filter on /spec, an then hit enter, I would expect to see only folders that contain files with the string "spec" in the name of the file, or in the name of the folder.

Is there any way to make it do that?

## Solution

Modified `lua/kickstart/plugins/neo-tree.lua`:
1. Mapped `f` to `filter_on_submit` instead of `fuzzy_finder` to allow the user to "hit enter" and apply a persistent filter.
2. Mapped `<esc>` to `clear_filter` to easily reset the tree view.
3. Set `filesystem.filtered_items.visible = false` so that non-matching files and folders are hidden rather than just dimmed.

This ensures that when a filter is applied (e.g., "spec"), only matching files/folders and their parent directories are visible.

---
**Completed in commit:** `<pending-commit-id>`
