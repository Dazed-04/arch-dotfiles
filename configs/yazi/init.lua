require("full-border"):setup()
require("folder-rules"):setup()
require("duckdb"):setup()

-- Show symlink target in status bar --
Status:children_add(function(self)
	local h = self._current.hovered
	if h and h.link_to then
		return " -> " .. tostring(h.link_to)
	end
	return ""
end, 3300, Status.LEFT)

-- Show user:group of the hovered file in status bar --
Status:children_add(function(self)
	local h = self._current.hovered
	if not h or ya.target_family() ~= "unix" then
		return ""
	end

	return ui.Line({
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
		":",
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
		" ",
	})
end, 500, Status.RIGHT)

-- Show username@hostname in header --
Header:children_add(function()
	if ya.target_family() ~= "unix" then
		return ""
	end
	return ui.Span((ya.user_name() or "") .. "@" .. (ya.host_name() or "") .. ":"):fg("blue")
end, 500, Header.LEFT)
