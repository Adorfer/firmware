-- image-customization.lua for Freifunk im Neanderland - Gluon 2025.1.x
--
-- Aufgeteilt auf vier Dateien. include() laedt flach aus dem Site-Verzeichnis,
-- Unterverzeichnisse gehen nicht (scripts/image_customization_lib.lua). Alle
-- Teile liegen deshalb nebeneinander in templates/common/ und landen ueber das
-- "cp -r -L templates/<domain>" in build.sh von selbst im Site-Verzeichnis -
-- die Domain-Vorlagen sind Symlinks auf common/.
--
--   image-customization.lua   Features und Pakete fuer alle Geraete,
--                             danach die Includes
--   ic-paketlisten.lua        die pkgs_*-Tabellen, reine Daten
--   ic-usb.lua                wer USB bekommt und wer nicht
--   ic-plattformen.lua        was an einzelnen Targets und Geraeten haengt
--
-- Die pkgs_*-Tabellen sind global, nicht local: include() setzt fuer jede
-- Datei dieselbe Umgebung (setfenv auf funcs), globale Namen sind darin also
-- ueber Dateigrenzen sichtbar. Ein "local" waere es nicht.
--
-- Reihenfolge ist bindend: ic-paketlisten vor ic-usb, sonst sind die Tabellen
-- beim Zugriff nil.

features {
    'autoupdater',
    'ebtables',
    'ebtables-filter-multicast',
    'ebtables-filter-ra-dhcp',
    'ebtables-limit-arp',
    'ebtables-source-filter',
    'mesh-batman-adv-15',
    -- Tunneldigger ist in Gluon 2025.1 kein Feature mehr (#3109). Der
    -- Dienst kommt als Paket aus den community-packages, die
    -- Konfigurationsseite bleibt ein Feature.
    'config-mode-mesh-vpn',
    'respondd',
    'status-page',
    'web-advanced',
    'web-wizard',
    'config-mode-geo-location-osm',
    'radv-filterd',
    'radvd',
    'authorized-keys',
    'web-private-wifi',
}


-- Herkunft hinter jedem Paket. Die Feeds und ihre Pins stehen nebenan in
-- "modules":
--
--   gluon             Gluon selbst, gluon/package/
--   gluon-packages    Feed "gluon"        freifunk-gluon/packages
--   community         Feed "community"    freifunk-gluon/community-packages
--   ffac              Feed "ffac"         ffac/gluon-packages
--   neanderfunk       Feed "neanderfunk"  Neanderfunk/packages
--   openwrt           OpenWrt-Basis
--   openwrt-packages  OpenWrt-Feed "packages"
--
-- Vorsicht: der Namensvorsatz sagt nichts ueber den Feed. ffac-ssid-changer,
-- ffac-autoupdater-wifi-fallback und ffac-update-location-gps liegen in
-- community-packages. Aus dem ffac-Feed kommt bei uns allein
-- ffac-web-private-wan-dhcp.
packages {
    'ff-mesh-vpn-tunneldigger',   -- community, ersetzt das Feature mesh-vpn-tunneldigger
    'gluon-ebtables-filter-ra-dhcp',      -- gluon
    'respondd-module-airtime',            -- gluon-packages
    'iwinfo',                             -- openwrt
    'haveged',                            -- openwrt-packages
    'socat',                              -- openwrt-packages
    'wireless-tools', 			  -- openwrt-packages
    'kmod-sched',                         -- openwrt, fuer socat
    'libc',                               -- openwrt, fuer socat
    'libpthread',                         -- openwrt, fuer socat
    'librt',                              -- openwrt, fuer socat
    'neanderfunk-weeklyreboot',           -- neanderfunk
    'neanderfunk-hotfix',                 -- neanderfunk
    'neanderfunk-linkcheck',              -- neanderfunk (wieder aktiv, Bugs 2026-09-06 behoben)
    'neanderfunk-txpowerfix',             -- neanderfunk
    'neanderfunk-preserve-wifichannel',   -- neanderfunk (ohne das Paket wirkt wifi24.preserve_channels der site.conf nicht)
    'neanderfunk-banner',                 -- neanderfunk
    'neanderfunk-migrate-updatebranch',   -- neanderfunk
    'neanderfunk-wifi-blackout',          -- neanderfunk (war eulenfunk-ath9kblackout)
    'neanderfunk-ssid-changer',           -- neanderfunk
    'neanderfunk-nodeplacer',             -- neanderfunk
    'neanderfunk-button-bind',            -- neanderfunk (Fork von ffffm-button-bind, Konflikt deklariert)
    'neanderfunk-node-whisperer',         -- neanderfunk (Fork von ffda-node-whisperer, Konflikt deklariert)
--    'ffac-ssid-changer',                -- community
    'ffac-autoupdater-wifi-fallback',     -- community
    'ff-ap-timer',                        -- community
    'ff-web-ap-timer',                    -- community
    'ffbs-collect-debug-info',            -- community
    'ffbs-debugbathosts',                 -- community
--    'ffmuc-ipv6-ra-filter',             -- community
}

-- "all devices" section finished

if not device_class('tiny') then
    features {
        'tls',
        'wireless-encryption-wpa3',
        'web-cellular',
        'mesh-vpn-sqm',
    }
    packages {
        'openssh-sftp-server',
        'ffda-gluon-usteer',              -- community
    }
end

if device({
        'zte-mf281',
        'glinet-gl-xe300',
        'glinet-gl-ap1300',
        'zte-mf289f',
        'zte-mf286r',
        'wavlink-ws-wn572hp3-4g',
        'tp-link-tl-mr6400-v5',
    }) then
    features {
        'web-cellular',
    }
    packages {
        'ffac-web-private-wan-dhcp',      -- ffac
    }
end


include('ic-paketlisten.lua')
include('ic-usb.lua')
include('ic-plattformen.lua')
