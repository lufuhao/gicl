#!/bin/bash
RootDir=$(cd `dirname $(readlink -f $0)`; pwd)
if [ ! -z $(uname -m) ]; then
	machtype=$(uname -m)
elif [ ! -z "$MACHTYPE" ]; then
	machtype=$MACHTYPE
else
	echo "Warnings: unknown MACHTYPE" >&2
fi
abs2rel () { perl -MFile::Spec -e 'print(File::Spec->abs2rel($ARGV[1], $ARGV[0]), "\n")' "$@"; }
ProgramName=${0##*/}
echo "MachType: $machtype"
echo "RootPath: $RootDir"
echo "ProgName: $ProgramName"

################# help message ######################################
help() {
cat<<HELP

$0 --- Brief Introduction

Version: 20160216

Requirements:
	Linux: X11, Motif, csh, PVM
	#NCBI toolkit
		sudo apt-get install xorg openbox libxmu-dev libmotif libxp-dev
		./ncbi/make/makedis.csh 2>&1 | tee out.makedis.txt

	##PVM
		sudo apt-get install pvm pvm-dev

Descriptions:
	Automatically configure, compile, setup GICL
	** NO mgblast setup

Options:
  -h    Print this help message
  -i    CONFIG file
  -t    Number of threads, default: 1
  -s    Not run simulation
  -a    Not run assembly

Example:
  $0 -i ./chr1.fa -t 10

Author:
  Fu-Hao Lu
  Post-Doctoral Scientist in Micheal Bevan laboratory
  Cell and Developmental Department, John Innes Centre
  Norwich NR4 7UH, United Kingdom
  E-mail: Fu-Hao.Lu@jic.ac.uk
HELP
exit 0
}
[ -z "$1" ] && help
[ "$1" = "-h" ] || [ "$1" = "--help" ] && help
#################### Environments ###################################
echo -e "\n######################\nProgram initializing ...\n######################\n"



#################### Initializing ###################################
uninstallprogram=0;
installprogram=0;
installcdbfasta=0;
installmblasm=0;
installmdust=0;
installmgblast=0;
installmgmerge=0;
installnrcl=0;
installpsx=0;
installpvmsx=0;
installsclust=0;
installtclust=0;
installtrimpoly=0;
installzmsort=0;
#################### Parameters #####################################
while [ -n "$1" ]; do
  case "$1" in
    -h) help;shift 1;;
    -i) installprogram=1 ;shift;;
    -u) uninstallprogram=1;shift;;
    -cdbfasta) installcdbfasta=1;shift;;
    -mblasm) installmblasm=1; shift;;
    -mdust) installmdust=1;shift;;
    -mgblast) installmgblast=1;shift;;
    -mgmerge) installmgmerge=1;shift;;
    -nrcl) installnrcl=1;shift;;
    -psx) installpsx=1;shift;;
    -pvmsx) installpvmsx=1;shift;;
    -sclust) installsclust=1; shift;;
    -tclust) installtclust=1; shift;;
    -trimpoly) installtrimpoly=1;shift;;
    -zmsort) installzmsort=1;shift;;
    --) shift;break;;
    -*) echo "error: no such option $1. -h for help" > /dev/stderr;exit 1;;
    *) break;;
  esac
done


#################### Defaults #######################################
dirmainbin=$RootDir/bin
if [ ! -d $dirmainbin ]; then
	echo "Error: no directory $RootDir/bin" >&2
	exit 1
fi
if [ ! -d $RootDir/programs ]; then
	echo "Error: no auxiliary programs folder" >&2
	exit 1
fi
dircdbtools=$RootDir/programs/cdbfasta
dirmblasm=$RootDir/programs/mblasm
dirmdust=$RootDir/programs/mdust
dirmgblast=$RootDir/programs/mgblast
dirmgmerge=$RootDir/programs/mgmerge
dirnrcl=$RootDir/programs/nrcl
dirpsx=$RootDir/programs/psx
dirpvmsx=$RootDir/programs/pvmsx
dirsclust=$RootDir/programs/sclust
dirtclust=$RootDir/programs/tclust
dirtrimpoly=$RootDir/programs/trimpoly
dirzmsort=$RootDir/programs/zmsort



#################### Subfuctions ####################################
###Detect command existence
CmdExists () {
  if command -v $1 >/dev/null 2>&1; then
    echo 0
  else
#    echo "I require $1 but it's not installed.  Aborting." >&2
    echo 1
  fi

}
DelDirFiles () {
	local -a tobedel=("$@")
	local tmpfilefolder
	for tmpfilefolder in "${tobedel[@]}"; do
#		echo "deleting $tmpfilefolder"
		if [ -d $tmpfilefolder ]; then
#			echo "deleting folder $tmpfilefolder"
			rm -rf $tmpfilefolder 1>/dev/null 2>/dev/null
			if [ $? -ne 0 ]; then
				echo -e "\nWarnings: Directory can not deleted\n" >&2
			fi
		elif [ -s $tmpfilefolder ]; then
#			echo "deleting file $tmpfilefolder"
			rm $tmpfilefolder 1>/dev/null 2>/dev/null
			if [ $? -ne 0 ]; then
				echo -e "\nWarnings: File can not deleted\n" >&2
			fi
		fi
	done
}
#if [ $(CmdExists 'tar') -ne 0 ]; then
#	echo "Error: CMD/script 'samtools' in PROGRAM 'SAMtools' is required but not found.  Aborting..." >&2 
#	exit 127
#fi



#################### uninstall ###############################
if [ $uninstallprogram -eq 1 ]; then
	echo -e "\n\n\nCleaning files"
	#clean cdbfasta
	echo -e "\tClean CDBtools"
	DelDirFiles "$dircdbtools" "$dirmainbin/cdbfasta" "$dirmainbin/cdbyank"
	echo -e "\tClean mblasm"
	DelDirFiles "$dirmblasm" "$dirmainbin/mblaor" "$dirmainbin/mblasm"
	echo -e "\tClean mdust"
	DelDirFiles "$dirmdust" "$dirmainbin/mdust"
	echo -e "\tClean mgblast"
	DelDirFiles "$dirmgblast" "$dirmainbin/mgblast"
	echo -e "\tClean mgmerge"
	DelDirFiles "$dirmgmerge" "$dirmainbin/mgmerge"
	echo -e "\tClean nrcl"
	DelDirFiles "$dirnrcl" "$dirmainbin/nrcl"
	echo -e "\tClean psx"
	DelDirFiles "$dirpsx" "$dirmainbin/psx"
	echo -e "\tClean pvmsx"
	DelDirFiles "$dirpvmsx" "$dirmainbin/pvmsx"
	echo -e "\tClean sclust"
	DelDirFiles "$dirsclust" "$dirmainbin/sclust"
	echo -e "\tClean tclust"
	DelDirFiles "$dirtclust" "$dirmainbin/tclust"
	echo -e "\tClean trimpoly"
	DelDirFiles "$dirtrimpoly" "$dirmainbin/trimpoly";
	echo -e "\tClean zmsort"
	DelDirFiles "$dirzmsort" "$dirmainbin/zmsort";
	exit 0;
fi



#################### Main ###########################################
### compiling cdbfasta
if [ $installprogram -eq 1 ] || [ $installcdbfasta -eq 1 ]; then
	programname="CDBtools"
	packagename="cdbfasta.tar.gz"
	echo -e "\n\n\n###### Compiling $programname #####"
	cd $RootDir/programs
	DelDirFiles "$dircdbtools" "$dirmainbin/cdbfasta" "$dirmainbin/cdbyank"
	if [ ! -s $packagename ]; then
		echo "Error: $programname source code $packagename not found" >&2
		exit 1
	fi
	tar xvf $packagename 1>/dev/null 2>/dev/null
	if [ $? -ne 0 ] || [ ! -d $dircdbtools ]; then
		echo "Error: uncompress $programname failed" >&2
		exit 1
	fi
	cd $dircdbtools
	make > make.log 2> make.err
	if [ $? -ne 0 ] || [ ! -s $dircdbtools/cdbfasta ] || [ ! -s $dircdbtools/cdbyank ]; then
		echo "Error: compiling $programname failed" >&2
		exit 1
	fi
	cp $dircdbtools/cdbfasta $dircdbtools/cdbyank $dirmainbin/
	if [ -s $dirmainbin/cdbfasta ] && [ -s $dirmainbin/cdbyank ]; then
		echo -e \t"$programname compiling successful"
		DelDirFiles "$dircdbtools"
	else
		echo "Error: can not copy $programname exectables to $dirmainbin/" >&2
		exit 1
	fi
fi



### mblasm
if [ $installprogram -eq 1 ] || [ $installmblasm -eq 1 ]; then
	programname="mblasm"
	packagename="mblasm.tar.gz"
	echo -e "\n\n\n###### Compiling $programname #####"
	cd $RootDir/programs
	DelDirFiles "$dirmblasm" "$dirmainbin/mblaor" "$dirmainbin/mblasm"
	if [ ! -s $packagename ]; then
		echo "Error: $programname source code $packagename not found" >&2
		exit 1
	fi
	tar xvf $packagename 1>/dev/null 2>/dev/null
	if [ $? -ne 0 ] || [ ! -d $dirmblasm ]; then
		echo "Error: uncompress $programname failed" >&2
		exit 1
	fi
	cd $dirmblasm
	make > make.log 2> make.err
	if [ $? -ne 0 ] || [ ! -s $dirmblasm/mblaor ] || [ ! -s $dirmblasm/mblasm ]; then
		echo "Error: compiling $programname failed" >&2
		exit 1trimpoly
	fi
	cp $dirmblasm/mblaor $dirmblasm/mblasm $dirmainbin/
	if [ -s $dirmainbin/mblaor ] && [ -s $dirmainbin/mblasm ]; then
		echo -e "\tcompiling $programname successful"
		DelDirFiles "$dirmblasm"
	else
		echo "Error: can not copy $programname exectables to $dirmainbin/" >&2
		exit 1
	fi
fi



### mdust
if [ $installprogram -eq 1 ] || [ $installmdust -eq 1 ]; then
	programname="mdust"
	packagename="mdust.tar.gz"
	echo -e "\n\n\n###### Compiling $programname #####"
	cd $RootDir/programs
	DelDirFiles "$dirmdust" "$dirmainbin/mdust"
	if [ ! -s $packagename ]; then
		echo "Error: $programname source code $packagename not found" >&2
		exit 1
	fi
	tar xvf $packagename 1>/dev/null 2>/dev/null
	if [ $? -ne 0 ] || [ ! -d $dirmdust ]; then
		echo "Error: uncompress $programname failed" >&2
		exit 1
	fi
	cd $dirmdust
	make > make.log 2> make.err
	if [ $? -ne 0 ] || [ ! -s $dirmdust/mdust ]; then
		echo "Error: compiling $programname failed" >&2
		exit 1
	fi
	cp $dirmdust/mdust $dirmainbin/
	if [ -s $dirmainbin/mdust ]; then
		echo -e "\tcompiling $programname successful"
		DelDirFiles "$dirmdust"
	else
		echo "Error: can not copy $programname exectables to $dirmainbin/" >&2
		exit 1
	fi
fi



### mgblast
if [ $installprogram -eq 1 ] || [ $installmgblast -eq 1 ]; then
	programname="mgblast"
	packagename="mgblast.tar.gz"
	echo -e "\n\n\n###### Compiling mgblast #####"
	cd $RootDir/programs
	DelDirFiles "$dirmgblast" "$dirmainbin/mgblast"
	if [ ! -s $packagename ]; then
		echo "Error: $programname source code $packagename not found" >&2
		exit 1
	fi
	tar xvf $packagename 1>/dev/null 2>/dev/null
	if [ $? -ne 0 ] || [ ! -d $dirmgblast ]; then
		echo "Error: uncompress $programname failed" >&2
		exit 1
	fi
	cd $dirmgblast
	make > make.log 2> make.err
	if [ $? -ne 0 ] || [ ! -s $dirmgblast/mgblast ]; then
		echo "Error: compiling $programname failed" >&2
		exit 1
	fi
	cp $dirmgblast/mgblast $dirmainbin/
	if [ -s $dirmainbin/mgblast ]; then
		echo -e "\tcompiling $programname successful"
		DelDirFiles "$dirmgblast"
	else
		echo "Error: can not copy $programname exectables to $dirmainbin/" >&2
		exit 1
	fi
fi



### mgmerge
if [ $installprogram -eq 1 ] || [ $installmgmerge -eq 1 ]; then
	programname="mgmerge"
	packagename="mgmerge.tar.gz"
	echo -e "\n\n\n###### Compiling $programname #####"
	cd $RootDir/programs
	DelDirFiles "$dirmgmerge" "$dirmainbin/mgmerge"
	if [ ! -s $packagename ]; then
		echo "Error: $programname source code $packagename not found" >&2
		exit 1
	fi
	tar xvf $packagename 1>/dev/null 2>/dev/null
	if [ $? -ne 0 ] || [ ! -d $dirmgmerge ]; then
		echo "Error: uncompress $programname failed" >&2
		exit 1
	fi
	cd $dirmgmerge
	make > make.log 2> make.err
	if [ $? -ne 0 ] || [ ! -s $dirmgmerge/mgmerge ]; then
		echo "Error: compiling $programname failed" >&2
		exit 1
	fi
	cp $dirmgmerge/mgmerge $dirmainbin/
	if [ -s $dirmainbin/mgmerge ]; then
		echo -e "\tcompiling $programname successful"
		DelDirFiles "$dirmgmerge"
	else
		echo "Error: can not copy $programname exectables to $dirmainbin/" >&2
		exit 1
	fi
fi



### nrcl
if [ $installprogram -eq 1 ] || [ $installnrcl -eq 1 ]; then
	programname="nrcl"
	packagename="nrcl.tar.gz"
	echo -e "\n\n\n###### Compiling $programname #####"
	cd $RootDir/programs
	DelDirFiles "$dirnrcl" "$dirmainbin/nrcl"
	if [ ! -s $packagename ]; then
		echo "Error: $programname source code $packagename not found" >&2
		exit 1
	fi
	tar xvf $packagename 1>/dev/null 2>/dev/null
	if [ $? -ne 0 ] || [ ! -d $dirnrcl ]; then
		echo "Error: uncompress $programname failed" >&2
		exit 1
	fi
	cd $dirnrcl
	make > make.log 2> make.err
	if [ $? -ne 0 ] || [ ! -s $dirnrcl/nrcl ]; then
		echo "Error: compiling $programname failed" >&2
		exit 1
	fi
	cp $dirnrcl/nrcl $dirmainbin/
	if [ -s $dirmainbin/nrcl ]; then
		echo -e "\tcompiling $programname successful"
		DelDirFiles "$dirnrcl"
	else
		echo "Error: can not copy $programname exectables to $dirmainbin/" >&2
		exit 1
	fi
fi



### psx
if [ $installprogram -eq 1 ] || [ $installpsx -eq 1 ]; then
	programname="psx"
	packagename="psx.tar.gz"
	echo -e "\n\n\n###### Compiling $programname #####"
	cd $RootDir/programs
	DelDirFiles "$dirpsx" "$dirmainbin/psx"
	if [ ! -s $packagename ]; then
		echo "Error: $programname source code $packagename not found" >&2
		exit 1
	fi
	tar xvf $packagename 1>/dev/null 2>/dev/null
	if [ $? -ne 0 ] || [ ! -d $dirpsx ]; then
		echo "Error: uncompress $programname failed" >&2
		exit 1
	fi
	cd $dirpsx
	make > make.log 2> make.err
	if [ $? -ne 0 ] || [ ! -s $dirpsx/psx ]; then
		echo "Error: compiling $programname failed" >&2
		exit 1
	fi
	cp $dirpsx/psx $dirmainbin/
	if [ -s $dirmainbin/psx ]; then
		echo -e "\tcompiling $programname successful"
		DelDirFiles "$dirpsx"
	else
		echo "Error: can not copy $programname exectables to $dirmainbin/" >&2
		exit 1
	fi
fi



### pvmsx
if [ $installprogram -eq 1 ] || [ $installpvmsx -eq 1 ]; then
	programname="pvmsx"
	packagename="pvmsx.tar.gz"
	echo -e "\n\n\n###### Compiling $programname #####"
	cd $RootDir/programs
	DelDirFiles "$dirpvmsx" "$dirmainbin/pvmsx"
	if [ ! -s $packagename ]; then
		echo "Error: $programname source code $packagename not found" >&2
		exit 1
	fi
	tar xvf $packagename 1>/dev/null 2>/dev/null
	if [ $? -ne 0 ] || [ ! -d $dirpvmsx ]; then
		echo "Error: uncompress $programname failed" >&2
		exit 1
	fi
	cd $dirpvmsx
	make > make.log 2> make.err
	if [ $? -ne 0 ] || [ ! -s $dirpvmsx/pvmsx ]; then
		echo "Error: compiling $programname failed" >&2
		exit 1
	fi
	cp $dirpvmsx/pvmsx $dirmainbin/
	if [ -s $dirmainbin/pvmsx ]; then
		echo -e "\tcompiling $programname successful"
		DelDirFiles "$dirpvmsx"
	else
		echo "Error: can not copy $programname exectables to $dirmainbin/" >&2
		exit 1
	fi
fi



### sclust
if [ $installprogram -eq 1 ] || [ $installsclust -eq 1 ]; then
	programname="sclust"
	packagename="sclust.tar.gz"
	echo -e "\n\n\n###### Compiling $programname #####"
	cd $RootDir/programs
	DelDirFiles "$dirsclust" "$dirmainbin/sclust"
	if [ ! -s $packagename ]; then
		echo "Error: $programname source code $packagename not found" >&2
		exit 1
	fi
	tar xvf $packagename 1>/dev/null 2>/dev/null
	if [ $? -ne 0 ] || [ ! -d $dirsclust ]; then
		echo "Error: uncompress $programname failed" >&2
		exit 1
	fi
	cd $dirsclust
	make > make.log 2> make.err
	if [ $? -ne 0 ] || [ ! -s $dirsclust/sclust ]; then
		echo "Error: compiling $programname failed" >&2
		exit 1
	fi
	cp $dirsclust/sclust $dirmainbin/
	if [ -s $dirmainbin/sclust ]; then
		echo -e "\tcompiling $programname successful"
		DelDirFiles "$dirsclust"
	else
		echo "Error: can not copy $programname exectables to $dirmainbin/" >&2
		exit 1
	fi
fi



### tclust
if [ $installprogram -eq 1 ] || [ $installtclust -eq 1 ]; then
	programname="tclust"
	packagename="tclust.tar.gz"
	echo -e "\n\n\n###### Compiling $programname #####"
	cd $RootDir/programs
	DelDirFiles "$dirtclust" "$dirmainbin/tclust"
	if [ ! -s $packagename ]; then
		echo "Error: $programname source code $packagename not found" >&2
		exit 1
	fi
	tar xvf $packagename 1>/dev/null 2>/dev/null
	if [ $? -ne 0 ] || [ ! -d $dirtclust ]; then
		echo "Error: uncompress $programname failed" >&2
		exit 1
	fi
	cd $dirtclust
	make > make.log 2> make.err
	if [ $? -ne 0 ] || [ ! -s $dirtclust/tclust ]; then
		echo "Error: compiling $programname failed" >&2
		exit 1
	fi
	cp $dirtclust/tclust $dirmainbin/
	if [ -s $dirmainbin/tclust ]; then
		echo -e "\tcompiling $programname successful"
		DelDirFiles "$dirtclust"
	else
		echo "Error: can not copy $programname exectables to $dirmainbin/" >&2
		exit 1
	fi
fi



### trimpoly
if [ $installprogram -eq 1 ] || [ $installtrimpoly -eq 1 ]; then
	programname="trimpoly"
	packagename="trimpoly.tar.gz"
	echo -e "\n\n\n###### Compiling $programname #####"
	cd $RootDir/programs
	DelDirFiles "$dirtrimpoly" "$dirmainbin/trimpoly"
	if [ ! -s $packagename ]; then
		echo "Error: $programname source code $packagename not found" >&2
		exit 1
	fi
	tar xvf $packagename 1>/dev/null 2>/dev/null
	if [ $? -ne 0 ] || [ ! -d $dirtrimpoly ]; then
		echo "Error: uncompress $programname failed" >&2
		exit 1
	fi
	cd $dirtrimpoly
	make > make.log 2> make.err
	if [ $? -ne 0 ] || [ ! -s $dirtrimpoly/trimpoly ]; then
		echo "Error: compiling $programname failed" >&2
		exit 1
	fi
	cp $dirtrimpoly/trimpoly $dirmainbin/
	if [ -s $dirmainbin/trimpoly ]; then
		echo -e "\tcompiling $programname successful"
		DelDirFiles "$dirtrimpoly"
	else
		echo "Error: can not copy $programname exectables to $dirmainbin/" >&2
		exit 1
	fi
fi



### zmsort
if [ $installprogram -eq 1 ] || [ $installzmsort -eq 1 ]; then
	programname="zmsort"
	packagename="zmsort.tar.gz"
	echo -e "\n\n\n###### Compiling $programname #####"
	cd $RootDir/programs
	DelDirFiles "$dirzmsort" "$dirmainbin/zmsort"
	if [ ! -s $packagename ]; then
		echo "Error: $programname source code $packagename not found" >&2
		exit 1
	fi
	tar xvf $packagename 1>/dev/null 2>/dev/null
	if [ $? -ne 0 ] || [ ! -d $dirzmsort ]; then
		echo "Error: uncompress $programname failed" >&2
		exit 1
	fi
	cd $dirzmsort
	make > make.log 2> make.err
	if [ $? -ne 0 ] || [ ! -s $dirzmsort/zmsort ]; then
		echo "Error: compiling $programname failed" >&2
		exit 1
	fi
	cp $dirzmsort/zmsort $dirmainbin/
	if [ -s $dirmainbin/zmsort ]; then
		echo -e "\tcompiling $programname successful"
		DelDirFiles "$dirzmsort"
	else
		echo "Error: can not copy $programname exectables to $dirmainbin/" >&2
		exit 1
	fi
fi


#if [ $? -ne 0 ] || [ ! -s $gffout ]; then
#	echo "GFFSORT_Error: sort error" >&2
#	exit 1
#fi


echo -e "\n\n\n###ADD following lines to your environments, like ~/.bashrc"
echo "export PATH=$RootDir/bin:"'$PATH'



exit 0;
