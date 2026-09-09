-- Wer USB-Unterstuetzung bekommt und wer nicht.
--
-- Setzt include_usb, nimmt es fuer einzelne Targets und Geraete wieder
-- zurueck und wendet am Ende die Listen aus ic-paketlisten.lua an. Diese
-- Datei setzt ic-paketlisten.lua voraus.

include_usb = true

-- rtl838x has no USB support as of Gluon v2023.2
if target('realtek', 'rtl838x') or target('ramips', 'mt7620') then
    include_usb = false
end

-- 7M usable firmware space + USB port
if target('ath79', 'generic') and not device({
    'devolo-wifi-pro-1750e',
    'gl.inet-gl-ar150',
    'gl.inet-gl-ar300m-lite',
    'gl.inet-gl-ar750',
    'joy-it-jt-or750i',
    'netgear-wndr3700-v2',
    'tp-link-archer-a7-v5',
    'tp-link-archer-c5-v1',
    'tp-link-archer-c7-v2',
    'tp-link-archer-c7-v5',
    'tp-link-archer-c59-v1',
    'tp-link-tl-wr842n-v3',
    'tp-link-tl-wr1043nd-v4',
    'tp-link-tl-wr1043n-v5',
}) then
    include_usb = false
end

if target('ramips', 'mt76x8') and not device({
    'gl-mt300n-v2',
    'gl.inet-microuter-n300',
    'netgear-r6120',
    'ravpower-rp-wd009',
}) then
    include_usb = false
end


-- 7M usable firmware space + USB port
if device({
    'avm-fritz-box-7412',
    'tp-link-td-w8970',
    'tp-link-td-w8980',
    'gl-mt300n-v2',
    'gl.inet-microuter-n300',
    'netgear-r6120',
    'ravpower-rp-wd009'
}) then
    include_usb = false
end

-- devices without usb ports
if device({
    'ubiquiti-unifi-6-lr-v1',
    'netgear-ex6150',
    'netgear-ex3700',
    -- Beide Namenspaare, weil patches/erx-ka-imagename.sh den ERX auf "-ka"
    -- umbenennt. Faellt der Rename spaeter weg, greifen wieder die oberen.
    'ubiquiti-edgerouter-x',
    'ubiquiti-edgerouter-x-sfp',
    'ubiquiti-edgerouter-x-ka',
    'ubiquiti-edgerouter-x-sfp-ka',
    'zyxel-nwa55axe',
}) then
    include_usb = false
end

if include_usb then
    packages(pkgs_usb)
    packages(pkgs_usb_net)
    packages(pkgs_usb_serial)
    packages(pkgs_usb_storage)
    packages {'ffka-gluon-web-usb-wan-hotplug', 'ffac-update-location-gps'}  -- beide community
end

