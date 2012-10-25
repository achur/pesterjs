exports.phone_number = (str) ->
  res = str.replace(/[^\d.]/g, "")
  if res.length == 10
    res
  else
    null
exports.format_phone = (str) ->
  str.substr(0, 3) + '-' + str.substr(3, 3) + '-' + str.substr(6,4)

