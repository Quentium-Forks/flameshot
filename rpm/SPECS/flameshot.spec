Name:       flameshot
Version:    14.0.0.0
Release:    1%{?dist}
Summary:    Powerful yet simple to use screenshot software

License:    GPLv3+
URL:        https://flameshot.org/
Source0:    %{name}-%{version}.tar.gz

%description
Notable features include customizable appearance, in-app screenshot editing, D-Bus interface, tray icon support, experimental GNOME/KDE Wayland support, integration with Imgur and support for both GUI and CLI interface.

%prep
%setup -q

%build
# Check if kdsingleapplication dependencies are installed
if rpm -q kdsingleapplication-qt6-devel; then
    EXTRA_FLAGS="-DUSE_BUNDLED_KDSINGLEAPPLICATION=OFF"
else
    EXTRA_FLAGS="-DUSE_BUNDLED_KDSINGLEAPPLICATION=ON"
fi

cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=%{_prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    $EXTRA_FLAGS

cmake --build build -j $(nproc)

%install
rm -rf %{buildroot}

DESTDIR=%{buildroot} cmake --install build

rm -rf %{buildroot}%{_includedir}/QtColorWidgets
rm -rf %{buildroot}%{_prefix}/lib/%{_arch}-linux-gnu/cmake/QtColorWidgets
rm -f %{buildroot}%{_prefix}/lib/%{_arch}-linux-gnu/libQtColorWidgets.*
rm -f %{buildroot}%{_prefix}/lib/%{_arch}-linux-gnu/pkgconfig/QtColorWidgets.pc
rm -rf %{buildroot}%{_includedir}/kdsingleapplication-qt6
rm -rf %{buildroot}%{_prefix}/lib/%{_arch}-linux-gnu/cmake/KDSingleApplication-qt6
rm -f %{buildroot}%{_prefix}/lib/%{_arch}-linux-gnu/libkdsingleapplication-qt6.*

%find_lang Internationalization --with-qt

%check
if command -v desktop-file-validate >/dev/null 2>&1; then
    desktop-file-validate %{buildroot}%{_datadir}/applications/org.flameshot.Flameshot.desktop
fi
if command -v appstream-util >/dev/null 2>&1; then
    appstream-util validate-relax --nonet %{buildroot}%{_datadir}/metainfo/org.flameshot.Flameshot.metainfo.xml
fi

%files -f Internationalization.lang
%doc README.md
%license LICENSE
%dir %{_datadir}/%{name}
%dir %{_datadir}/%{name}/translations
%dir %{_datadir}/bash-completion/completions
%dir %{_datadir}/zsh/site-functions
%{_bindir}/%{name}
%{_datadir}/applications/org.flameshot.Flameshot.desktop
%{_datadir}/metainfo/org.flameshot.Flameshot.metainfo.xml
%{_datadir}/bash-completion/completions/%{name}
%{_datadir}/zsh/site-functions/_%{name}
%{_datadir}/fish/vendor_completions.d/%{name}.fish
%{_datadir}/dbus-1/interfaces/org.flameshot.Flameshot.xml
%{_datadir}/dbus-1/services/org.flameshot.Flameshot.service
%{_datadir}/icons/hicolor/*/apps/*.png
%{_datadir}/icons/hicolor/scalable/apps/*.svg
%{_mandir}/man1/%{name}.1*

%changelog
