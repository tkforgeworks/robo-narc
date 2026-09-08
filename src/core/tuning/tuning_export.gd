class_name TuningExport
extends RefCounted
## Renders the values that differ from the shipped defaults (config and
## per-style) as `.tres` resource lines an operator can paste into the
## defaults file. Read-only over a TuningService.


## `{"tuning": {name: value}, "styles": {key: {name: value}}}`.
static func tuned_values(tuning: TuningService) -> Dictionary:
	var defaults := TuningService.load_defaults()
	var changed := {}
	for property_name in TunableProperties.names(tuning.config):
		var value: Variant = tuning.config.get(property_name)
		if not TuningStore.same_value(value, defaults.get(property_name)):
			changed[property_name] = value
	var styles := {}
	for style in tuning.get_styles():
		var shipped := TuningService.shipped_style(style)
		var diff := {}
		for property_name in TunableProperties.names(style):
			if property_name == "key":
				continue
			var value: Variant = style.get(property_name)
			if shipped == null or not TuningStore.same_value(value, shipped.get(property_name)):
				diff[property_name] = value
		if not diff.is_empty():
			styles[str(style.get("key"))] = diff
	return {"tuning": changed, "styles": styles}


static func text(tuning: TuningService) -> String:
	var values := tuned_values(tuning)
	var lines := PackedStringArray()
	lines.append("# tuned values vs %s" % TuningService.DEFAULTS_PATH.get_file())
	if values["tuning"].is_empty() and values["styles"].is_empty():
		lines.append("# (none: everything is at the shipped default)")
	for property_name: String in values["tuning"]:
		lines.append("%s = %s" % [property_name, var_to_str(values["tuning"][property_name])])
	for key: String in values["styles"]:
		lines.append("")
		lines.append("# style %s" % key)
		for property_name: String in values["styles"][key]:
			lines.append("%s = %s" % [property_name, var_to_str(values["styles"][key][property_name])])
	return "\n".join(lines)
