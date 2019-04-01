#!/usr/local/bin/cbsd
# Wrapper for creating debootstrap environvent via 2 phases:
# 1) Get distribution into skel dir from FTP
# 2) Get distribution into data dir from skel dir

. /etc/rc.conf

if [ -z "${cbsd_workdir}" ]; then
	echo "No workdir"
	exit 1
fi

workdir="${cbsd_workdir}"

[ ! -f "${distdir}/cbsd.conf" ] && exit 1
. ${distdir}/cbsd.conf
. ${subr}
. ${system}
. ${strings}
. ${tools}

SRC_MIRROR="http://ftp.us.debian.org/debian"
# + http://deb.debian.org/debian/
customskel="${sharedir}/FreeBSD-jail-kfreebsd-wheezy-skel"

[ -z "${jname}" ] && err 1 "${MAGENTA}Empty jname${NORMAL}"

[ ! -d ${customskel} ] && /bin/mkdir -p ${customskel}

if [ ! -x /usr/local/sbin/debootstrap ]; then
	err 1 "${MAGENTA}No such debootstrap. Please ${GREEN}pkg install debootstrap${MAGENTA} it.${NORMAL}"
fi

for module in linprocfs fdescfs tmpfs linsysfs; do
	/sbin/kldstat -m "$module" > /dev/null 2>&1 || /sbin/kldload ${module}
done

if [ ! -f ${customskel}/bin/bash ]; then
	export INTER=1

	if getyesno "Shall i download distribution via deboostrap from ${SRC_MIRROR}?"; then
		${ECHO} "${MAGENTA}debootstrap ${LCYAN}--include=openssh-server,locales,joe,rsync,sharutils,psmisc,htop,patch,less,apt --components main,contrib ${LYELLOW}wheezy ${MAGENTA}${customskel} ${SRC_MIRROR}${NORMAL}"
		debootstrap --include=openssh-server,locales,joe,rsync,sharutils,psmisc,htop,patch,less,apt --components main,contrib wheezy ${customskel} ${SRC_MIRROR}
		chroot ${customskel} dpkg -i /var/cache/apt/archives/*.deb
	else
		echo "No such distribution"
		exit 1
	fi
fi

[ ! -f ${customskel}/bin/bash ] && err 1 "${MAGENTA}No such distribution on ${GREEN}${customskel}${NORMAL}"

. ${jrcconf}
[ "$baserw" = "1" ] && path=${data}

. ${distdir}/freebsd_world.subr
customskel

[ ! -f ${data}/bin/bash ] && err 1 "${MAGENTA}No such ${data}/bin/bash"
exit 0

