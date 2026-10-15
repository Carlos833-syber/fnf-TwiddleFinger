-- Exercise the shipped event script with its engine callbacks.
local calls = {}
function cancelTween(tag)
    assert(tag == 'asf')
    calls[#calls + 1] = 'cancel'
end
function doTweenZoom(tag, camera, zoom, duration, easing)
    assert(tag == 'asf' and camera == 'camGame')
    assert(zoom == '1.2' and duration == '0.5' and easing == 'cubeOut')
    calls[#calls + 1] = 'tween'
end
function setProperty(property, value)
    assert(property == 'defaultCamZoom' and value == '1.2')
    calls[#calls + 1] = 'property'
end
assert(loadfile('example_mods/custom_events/infryzoom.lua'))()
onEvent('another event', '1.2', '0.5')
assert(#calls == 0)
onEvent('infryzoom', '1.2', '0.5')
assert(table.concat(calls, ',') == 'cancel,tween,property')
print('infryzoom native Lua smoke test passed')
