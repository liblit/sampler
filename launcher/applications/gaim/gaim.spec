Summary:    A Gtk+ based multiprotocol instant messaging client
Name:       gaim
Version:    0.66
Release:    1.sam.1
Epoch:      1
License:    GPL
Group:      Applications/Internet
Vendor:     Computer Science Division, UC Berkeley
Url:        http://gaim.sourceforge.net/
Source:     %{name}-%{version}.tar.gz
Packager:   Ben Liblit <liblit@cs.berkeley.edu>
BuildRoot:  %{_tmppath}/%{name}-%{version}-root
%if %{_vendor} != MandrakeSoft
Requires:   gtk2 >= 2.0.0
BuildRequires: libao-devel, gtk2-devel, gtkspell-devel, libtool, audiofile-devel
%else
Requires:   gtk+2.0 >= 2.0.0
BuildRequires: libao-devel, libgtk+2.0_0-devel, gtkspell-devel, libtool, audiofile-devel
%endif
%sampler_tags

%package devel
Summary: Development headers, documentation, and libraries for Gaim.
Group: Applications/Internet

%description
Gaim allows you to talk to anyone using a variety of messaging 
protocols, including AIM (Oscar and TOC), ICQ, IRC, Yahoo!, 
MSN Messenger, Jabber, Gadu-Gadu, Napster, and Zephyr.  These 
protocols are implemented using a modular, easy to use design.  
To use a protocol, just load the plugin for it.

Gaim supports many common features of other clients, as well as many 
unique features, such as perl scripting and C plugins.

Gaim is NOT affiliated with or endorsed by AOL.

%sampler_description

%description devel

The gaim-devel package contains the header files, developer
documentation, and libraries required for development of gaim scripts
and plugins.

%sampler_description

%sampler_package

%prep
%setup
%sampler_prep

%build
%sampler_build
CFLAGS="$RPM_OPT_FLAGS" ./configure --prefix=%{_prefix} \
                                    --bindir=%{_bindir} \
                                    --datadir=%{_datadir} \
                                    --includedir=%{_includedir} \
                                    --libdir=%{_libdir} \
                                    --mandir=%{_mandir} \
                                    --sysconfdir=%{_sysconfdir}
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
make prefix=%{buildroot}%{_prefix} bindir=%{buildroot}%{_bindir} \
     datadir=%{buildroot}%{_datadir} includedir=%{buildroot}%{_includedir} \
     libdir=%{buildroot}%{_libdir} mandir=%{buildroot}%{_mandir} \
     sysconfdir=%{buildroot}%{_sysconfdir} \
     install
%sampler_install

%clean
rm -rf %{buildroot}

%files
%defattr(-, root, root)

%doc doc/the_penguin.txt doc/CREDITS doc/FAQ NEWS COPYING AUTHORS
%doc README ChangeLog
%doc %{_mandir}/man1/*

%attr(755, root, root) %{_libdir}/gaim/*
%attr(755, root, root) %{_libdir}/libgaim-remote.so.*
%{_bindir}/*
%{_datadir}/locale/*/*/*
%{_datadir}/pixmaps/*
%{_datadir}/sounds/gaim/*
%{_datadir}/applications/*
%sampler_files

%files devel

%doc plugins/SIGNALS plugins/HOWTO plugins/PERL-HOWTO 
%doc HACKING TODO

%attr(755, root, root) %{_libdir}/libgaim-remote.la
%{_includedir}/gaim-remote/*.h

%post
%sampler_post

%changelog
* Fri Aug  8 2003 Ben Liblit <liblit@cs.berkeley.edu> 1:@VERSION@-1
- Added sampled instrumentation.

* Wed Jul 16 2003 Ethan Blanton <eblanton@cs.ohiou.edu>
- Complete spec file rewrite to take advantage of "new" RPM features
  and make things prettier.
- Use system-supplied %%{_prefix}, %%{_datadir}, etc. rather than
  attempt to define our own.
