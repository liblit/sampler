%define subver   1.3
%define microver 18
%define ver      1.3.18
%define prefix	 /usr
%define sysconfdir	/etc

Summary: The GNU Image Manipulation Program
Name: 		gimp
Version: 	%{ver}
Release: 	1.sam.1
Epoch:		1
Copyright: 	GPL, LGPL
Group: 		Applications/Graphics
URL: 		http://www.gimp.org/
BuildRoot: 	%{_tmppath}/%{name}-%{ver}-root
Docdir:		%{prefix}/doc
Prefix:		%{prefix}
Obsoletes: 	gimp-data-min
Obsoletes:	gimp-libgimp
Requires: 	gtk2 >= 2.2.0
Requires:	libart_lgpl >= 2.0
Requires:	fontconfig >= 1.0.1
Requires:	gimp-print >= 4.2.0
Requires:	gtkhtml2 >= 1.99.5
Source: 	ftp://ftp.gimp.org/pub/gimp/v%{subver}/%{name}-%{ver}.tar.bz2
%{?sampler_tags}
Packager:	Ben Liblit <liblit@cs.berkeley.edu>
Vendor:		UC Berkeley
Distribution:	Sampler

%description
The GIMP (GNU Image Manipulation Program) is a powerful image
composition and editing program, which can be extremely useful for
creating logos and other graphics for Web pages.  The GIMP has many of
the tools and filters you would expect to find in similar commercial
offerings, and some interesting extras as well. The GIMP provides a
large image manipulation toolbox, including channel operations and
layers, effects, sub-pixel imaging and anti-aliasing, and conversions,
all with multi-level undo.

The GIMP includes a scripting facility, but many of the included
scripts rely on fonts that we cannot distribute.  The GIMP FTP site
has a package of fonts that you can install by yourself, which
includes all the fonts needed to run the included scripts.  Some of
the fonts have unusual licensing requirements; all the licenses are
documented in the package.  Get
ftp://ftp.gimp.org/pub/gimp/fonts/freefonts-0.10.tar.gz and
ftp://ftp.gimp.org/pub/gimp/fonts/sharefonts-0.10.tar.gz if you are so
inclined.  Alternatively, choose fonts which exist on your system
before running the scripts.

Install the GIMP if you need a powerful image manipulation
program. You may also want to install other GIMP packages:
gimp-libgimp if you're going to use any GIMP plug-ins and
gimp-data-extras, which includes various extra files for the GIMP.

%{?sampler_description}

%package devel
Summary: GIMP plugin and extension development kit
Group: 		Applications/Graphics
Requires: 	gtk2-devel
%description devel
The gimp-devel package contains the static libraries and header files
for writing GNU Image Manipulation Program (GIMP) plug-ins and
extensions.

Install gimp-devel if you're going to create plug-ins and/or
extensions for the GIMP.  You'll also need to install gimp-limpgimp
and gimp, and you may want to install gimp-data-extras.

%{?sampler_description}

%package docs
Summary: GIMP Documentation
Group: Applications/Graphics
%description docs
GIMP documentation

%{?sampler_description}

%{?sampler_package}

%prep
%setup -q
%{?sampler_prep}

%build
%{?sampler_prebuild}
%ifarch alpha
MYARCH_FLAGS="--host=alpha-redhat-linux"
%endif

if [ ! -f configure ]; then
  CFLAGS="$RPM_OPT_FLAGS" ./autogen.sh --quiet $MYARCH_FLAGS --prefix=%{prefix}
else
  CFLAGS="$RPM_OPT_FLAGS" %configure --quiet
fi
make

%install
[ -n "$RPM_BUILD_ROOT" -a "$RPM_BUILD_ROOT" != / ] && rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{prefix}/info $RPM_BUILD_ROOT/%{prefix}/include \
	$RPM_BUILD_ROOT/%{prefix}/lib $RPM_BUILD_ROOT/%{prefix}/bin
make destdir=$RPM_BUILD_ROOT DESTDIR=$RPM_BUILD_ROOT install

#
# Plugins and modules change often (grab the executeable ones)
#
echo "%defattr (0555, bin, bin)" > gimp-plugin-files
find $RPM_BUILD_ROOT/%{prefix}/lib/gimp/%{subver} -type f -exec file {} \; | cut -d':' -f 1 | sed "s@^$RPM_BUILD_ROOT@@g"  >>gimp-plugin-files

#
# Tips
#
echo "%defattr (444, bin, bin, 555)" >gimp-tips-files

#
# Build the master filelists generated from the above mess.
#
cat gimp-plugin-files gimp-tips-files > gimp.files

%define sampler_wrapped %{_bindir}/%{name}-%{subver}
%{?sampler_install}

%clean
[ -n "$RPM_BUILD_ROOT" -a "$RPM_BUILD_ROOT" != / ] && rm -rf $RPM_BUILD_ROOT

%post
/sbin/ldconfig
%{?sampler_post}

%postun -p /sbin/ldconfig

%files -f gimp.files
%attr (0555, bin, man) %doc AUTHORS COPYING ChangeLog MAINTAINERS NEWS README
%attr (0555, bin, man) %doc docs/*.txt README.i18n README.win32
%defattr (0444, bin, bin, 0555)
%dir %{prefix}/share/gimp/%{subver}
%dir %{prefix}/share/gimp/%{subver}/tips
%dir %{prefix}/lib/gimp/%{subver}
%dir %{prefix}/lib/gimp/%{subver}/modules
%dir %{prefix}/lib/gimp/%{subver}/plug-ins

%{prefix}/share/gimp/%{subver}/brushes/
%{prefix}/share/gimp/%{subver}/fractalexplorer/
%{prefix}/share/gimp/%{subver}/gfig/
%{prefix}/share/gimp/%{subver}/gflare/
%{prefix}/share/gimp/%{subver}/gimpressionist/
%{prefix}/share/gimp/%{subver}/gradients/
%{prefix}/share/gimp/%{subver}/palettes/
%{prefix}/share/gimp/%{subver}/patterns/
%{prefix}/share/gimp/%{subver}/scripts/

%{sysconfdir}/gimp/%{subver}/gtkrc_user
%{sysconfdir}/gimp/%{subver}/unitrc
%{sysconfdir}/gimp/%{subver}/ps-menurc

%defattr (0555, bin, bin)

%{prefix}/lib/libgimp-%{subver}.so.%{microver}.0.0
%{prefix}/lib/libgimp-%{subver}.so.%{microver}
%{prefix}/lib/libgimpui-%{subver}.so.%{microver}.0.0
%{prefix}/lib/libgimpui-%{subver}.so.%{microver}
%{prefix}/lib/libgck-%{subver}.so.%{microver}.0.0
%{prefix}/lib/libgck-%{subver}.so.%{microver}

# 1.3
%{prefix}/lib/libgimpbase-%{subver}.so.%{microver}.0.0
%{prefix}/lib/libgimpbase-%{subver}.so.%{microver}
%{prefix}/lib/libgimpcolor-%{subver}.so.%{microver}.0.0
%{prefix}/lib/libgimpcolor-%{subver}.so.%{microver}
%{prefix}/lib/libgimpmath-%{subver}.so.%{microver}.0.0
%{prefix}/lib/libgimpmath-%{subver}.so.%{microver}
%{prefix}/lib/libgimpwidgets-%{subver}.so.%{microver}.0.0
%{prefix}/lib/libgimpwidgets-%{subver}.so.%{microver}
%{prefix}/lib/libgimpmodule-%{subver}.so.%{microver}.0.0
%{prefix}/lib/libgimpmodule-%{subver}.so.%{microver}

%{prefix}/share/gimp/%{subver}/images
%{prefix}/share/gimp/%{subver}/misc
%{prefix}/share/gimp/%{subver}/themes
%{prefix}/share/gimp/%{subver}/tips/gimp-tips.xml

%{prefix}/share/locale/

%{prefix}/share/man/man1/*
%{prefix}/share/man/man5/*

%{prefix}/bin/gimp-1.3
%{prefix}/bin/gimp-remote-1.3

%{?sampler_files}

%defattr (0444, bin, man)

%files devel
%defattr (0555, bin, bin, 0555)
%{prefix}/bin/gimptool-1.3
%{prefix}/lib/*.so
%{prefix}/lib/*.la
%dir %{prefix}/lib/gimp/%{subver}
%dir %{prefix}/lib/gimp/%{subver}/modules
%{prefix}/lib/gimp/%{subver}/modules/*.la

%defattr (0444, root, root, 0555)
#new stuff 1.3
/etc/gimp/%{subver}/gimprc
/etc/gimp/%{subver}/sessionrc
/etc/gimp/%{subver}/templaterc
%{prefix}/lib/pkgconfig/gimp-1.3.pc
%{prefix}/lib/pkgconfig/gimpui-1.3.pc

%dir %{prefix}/include/gimp-%{subver}/gck
%{prefix}/include/gimp-%{subver}/gck/*

%dir %{prefix}/include/gimp-%{subver}/libgimpbase
%{prefix}/include/gimp-%{subver}/libgimpbase/*

%dir %{prefix}/include/gimp-%{subver}/libgimpmath
%{prefix}/include/gimp-%{subver}/libgimpmath/*

%dir %{prefix}/include/gimp-%{subver}/libgimpmodule
%{prefix}/include/gimp-%{subver}/libgimpmodule/*

%dir %{prefix}/include/gimp-%{subver}/libgimpwidgets
%{prefix}/include/gimp-%{subver}/libgimpwidgets/*

%dir %{prefix}/include/gimp-%{subver}/libgimpcolor
%{prefix}/include/gimp-%{subver}/libgimpcolor/*

%{prefix}/share/aclocal/gimp-2.0.m4

%{prefix}/lib/*.a
%{prefix}/lib/gimp/%{subver}/modules/*.a

%{prefix}/include/gimp-%{subver}/libgimp

%files docs
%{prefix}/share/gtk-doc/html/libgimp
%{prefix}/share/gtk-doc/html/libgimpbase
%{prefix}/share/gtk-doc/html/libgimpcolor
%{prefix}/share/gtk-doc/html/libgimpmath
%{prefix}/share/gtk-doc/html/libgimpmodule
%{prefix}/share/gtk-doc/html/libgimpwidgets

%changelog
* Tue Aug 19 2003 Ben Liblit <liblit@cs.berkeley.edu> 1.3.18-1.sam.1
- Added hooks for sampled instrumentation.

* Sun Aug 10 2003 Ville P�tsi <drc@gimp.org>
- Bring gtk2 package names up to date
- Change PREFIX to DESTDIR
- Change files to match what 1.3 uses.
- Remove lots of obsolete (?) macros

* Fri Apr 14 2000 Matt Wilson <msw@redhat.com>
- include subdirs in the help find
- remove gimp-help-files generation
- both gimp and gimp-perl own prefix/lib/gimp/1.1/plug-ins
- both gimp and gimp-devel own prefix/lib/gimp/1.1 and
  prefix/lib/gimp/1.1/modules

* Thu Apr 13 2000 Matt Wilson <msw@redhat.com>
- 1.1.19
- get all .mo files

* Wed Jan 19 2000 Gregory McLean <gregm@comstar.net>
- Version 1.1.15

* Wed Dec 22 1999 Gregory McLean <gregm@comstar.net>
- Version 1.1.14
- Added some auto %files section generation scriptlets


