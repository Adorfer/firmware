-- Was an einzelnen Targets und Geraeten haengt und nichts mit USB zu tun hat.

-- device has no reset button and requires a special package to go into setup mode
-- https://github.com/freifunk-gluon/community-packages/tree/master/ffda-network-setup-mode
if device({
    'zyxel-nwa55axe',
}) then
    packages {'ffda-network-setup-mode'}  -- community
    broken(false)
end

if target('x86', '64') then
    -- add guest agent for qemu and vmware
    packages {
        'qemu-ga',
        'open-vm-tools',                 -- openwrt-packages
    	'kmod-vmxnet3',
    }
end

if target('x86') and not target('x86', 'legacy') then
    packages(pkgs_pci)
    packages(pkgs_hid)
end

if target('bcm27xx') then
    packages(pkgs_hid)
end

-- Das mt7915-Backlog-Problem (openwrt/mt76#1009) ist unter Gluon 2025.1
-- upstream behoben. Weder die Vorbeugung ueber max_inactivity noch die
-- Symptombehandlung durch neanderfunk-mt7915-backlog werden hier noch
-- gebraucht; auf v2023.2.x bleiben beide.

