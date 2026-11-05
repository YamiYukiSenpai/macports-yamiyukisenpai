# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#
# Shared settings for KDE Frameworks 6 (and KF6-based applications) on macOS.
#
# Usage, for a framework:
#
#   PortSystem      1.0
#   PortGroup       kf6 1.0
#   kf6.setup       karchive
#
# For a KDE Gear application (e.g. kate), include the PortGroup and set
# name/version/master_sites yourself; the common cmake/Qt settings still apply.
#
# Design notes:
#   * Qt 6 comes from the official qt6-* ports (${prefix}/libexec/qt6) and is
#     located through cmake.prefix_path.
#   * KDE_INSTALL_USE_QT_SYS_PATHS=ON puts Qt plugins and QML modules into the
#     Qt 6 tree, so Qt's default plugin path finds them at runtime.
#   * DBus and X11/Wayland are off, which is upstream's default on macOS.
#   * Python bindings, QCH docs, designer plugins, tests and KDocTools
#     handbooks are disabled to keep the dependency tree small.

PortGroup               qt6 1.0
PortGroup               cmake 1.1

# KF6 release used by every framework port in this tree. Bump this (and the
# checksums in each framework Portfile) to update all frameworks at once.
options                 kf6.version kf6.branch
default                 kf6.version     6.31.0
default                 kf6.branch      {[join [lrange [split [option kf6.version] .] 0 1] .]}

qt6.find_method         prefix_path

# KF6 requires C++20
compiler.cxx_standard   2020

configure.args-append   -DBUILD_TESTING:BOOL=OFF \
                        -DBUILD_QCH:BOOL=OFF \
                        -DBUILD_PYTHON_BINDINGS:BOOL=OFF \
                        -DBUILD_DESIGNERPLUGIN:BOOL=OFF \
                        -DUSE_DBUS:BOOL=OFF \
                        -DWITH_X11:BOOL=OFF \
                        -DKDE_INSTALL_USE_QT_SYS_PATHS:BOOL=ON \
                        -DKDE_INSTALL_BUNDLEDIR:PATH=${applications_dir} \
                        -DCMAKE_DISABLE_FIND_PACKAGE_KF6DocTools:BOOL=ON

depends_build-append    port:kde-extra-cmake-modules

# kf6.link_appsupport <dir> ...
#   On macOS, Qt's QStandardPaths::GenericDataLocation (used by KDE for color
#   schemes, translations, search providers, ...) only searches
#   ~/Library/Application Support and /Library/Application Support -- never
#   ${prefix}/share, and not the app bundle either. For each <dir>, install a
#   symlink /Library/Application Support/<dir> -> ${prefix}/share/<dir>.
#
#   WARNING: this installs outside ${prefix}, which official MacPorts policy
#   does not allow. It is fine for this private tree, but these ports cannot
#   be submitted upstream as-is (see CLAUDE.md).
options                 kf6.appsupport_links
default                 kf6.appsupport_links {}

proc kf6.link_appsupport {args} {
    kf6.appsupport_links-append {*}${args}
    destroot.violate_mtree  yes
}

post-destroot {
    if {[llength [option kf6.appsupport_links]] > 0} {
        set appsupport "${destroot}/Library/Application Support"
        xinstall -d ${appsupport}
        foreach dir [option kf6.appsupport_links] {
            ln -s ${prefix}/share/${dir} [file join ${appsupport} ${dir}]
        }
    }
}

# kf6.setup <framework>
#   Sets name, version, distfile location, homepage and livecheck for a
#   framework released under download.kde.org/stable/frameworks/.
proc kf6.setup {framework} {
    set branch          [option kf6.branch]

    name                kf6-${framework}
    version             [option kf6.version]
    categories          kde devel
    maintainers         nomaintainer
    homepage            https://invent.kde.org/frameworks/${framework}

    master_sites        https://download.kde.org/stable/frameworks/${branch}/
    distname            ${framework}-[option kf6.version]
    use_xz              yes

    livecheck.type      regex
    livecheck.url       https://download.kde.org/stable/frameworks/
    livecheck.version   ${branch}
    livecheck.regex     {href="(6\.[0-9]+)/"}
}
