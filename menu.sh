#! /bin/bash

Check(){
if [[ -a $1 ]]; then
    Result='1'
else
    Result='0'
fi
}

IMGFiles="super system system_ext product odm vendor"
BRFiles="system vendor system_ext product odm"
DATFiles="system vendor system_ext product odm"
BINFiles="payload"


Check bin
if [[ $Result == 0 ]];then
    echo "./Bin not found,Download!"
    wget https://hub.fastgit.org/wwrrj/AIUT/releases/download/v1.1/bin.zip > /dev/null 2>&1
    Check bin.zip
    if [[ $Result == 1 ]];then
        unzip -d ./bin bin.zip
        rm -rf binary.zip
        clear
        echo "Done!!!"
    else
        echo "Download failed!Please download it by yourself and put it into the AIUT folder"
        echo "Download link: https://hub.fastgit.org/wwrrj/AIUT/releases/download/v1.1/bin.zip"
        exit
    fi
fi

Info(){
    echo "----------------------------------"
    echo "The last run result: " 
    cat ./bin/.create
    Check IMG/boot/imageinfo.txt
    if [[ $Result == 1 ]];then
        echo "----------------------------------"
        echo "Kernel info: "
        cat IMG/boot/imageinfo.txt | grep BOARD
        echo "----------------------------------"
        echo "[boot.img/recovery.img] --> IMG/boot"
    fi
    echo "----------------------------------"
}

Menu(){
    echo "----------------------------------"
    echo "一.分解专区"
    echo "  1.system.new.dat.br --> system.new.dat"
    echo "  2.system.new.dat --> system.img"
    echo "  3.vendor.new.dat.br --> vendor.new.dat"
    echo "  4.vendor.new.dat --> vendor.img"
    echo "  5.分解system.img"
    echo "  6.分解vendor.img"
    echo "  7.分解boot/recovery.img"
    echo "  8.分解Payload.bin"
    echo "  9.解压Zip刷机包"
    echo "  10.清理工具"
    echo "----------------------------------"
}

AutoUnpack(){
    DecompressIMG(){
        for i in $IMGFiles; do
            if [[ -e Input/$i.img ]];then
                echo "[UNPACKIMG]: $i.img"
                UnpackIMG $i
            fi
        done
    }

    DecompressDAT(){
        for d in $DATFiles; do
            if [[ -e Input/$d.new.dat ]];then
                echo "[UNPACKDAT]: $d.new.dat"                
                UnpackDat $d
            fi
        done

        DecompressIMG
    }

    DecompressBR(){
        for b in $BRFiles; do
            if [[ -e Input/$b.new.dat.br ]];then
                echo "[UNPACKBR]: $b.new.dat.br"
                UnpackBr $b
            fi
        done

        DecompressDAT
    }

    DecompressBIN(){
        for bin in $BINFiles; do
            if [[ -e Input/$bin.bin ]];then
                echo "[UNPACKBIN]: $bin.bin"
                Payload
            fi
        done

        DecompressIMG
    }

    UnpackZIP(){
        echo "[UNZIP]: Working..."        
        7z x Input/$name -o./Input > ./bin/log
        if [[ $(cat ./bin/log | grep "Everything is Ok") == "Everything is Ok" ]];then
            Unzip="Done"
            rm -rf ./bin/log
        fi
    }

    if [[ $(ls Input | grep META-INF) == META-INF ]];then
        mv Input rubbishbin
        mkdir Input
    fi

    read -p "File name: " name

    Check Input/$name
    if [[ $Result == 1 ]];then
        UnpackZIP
    elif [[ $Result == 0 ]];then
        Check rubbishbin/$name
        if [[ $Result == 1 ]];then
            mv rubbishbin/$name Input/$name
            rm -rf rubbishbin
            UnpackZIP
        fi

        if [[ $Result == 0 ]];then
            echo "File not found!!!"
        fi
    fi
    
    if [[ $Unzip == "Done" ]];then
        DecompressBIN
        DecompressBR
    fi
}

Usage(){
    echo "Usage: bash $0 <Tool Options> [--m] [ --c]"
    echo -e "\tTool Options: You can enter $0 --m to view Tool Options"
    echo -e "\t--m: Show options"
    echo -e "\t--u: Unpack Android Images"
    echo -e "\t--c: Clean up tool path"
}

Clean(){
    rm -rf Input/*
    echo "Done!Back to main menu!" > ./bin/.create
}

UnpackBr(){
    Check Input/$1.new.dat
    if [[ $Result == 0 ]];then
        ./bin/brotli -d Input/$1.new.dat.br
        Check Input/$1.new.dat
        if [[ $Result == 1 ]];then
            echo "Done!!!!!!!" > ./bin/.create
         else
            echo "Fuck!!!Where's my $1.new.dat?!!" > ./bin/.create
        fi
    else
        rm -rf Input/$1.new.dat
        UnpackBr $1
    fi
}

UnpackDat(){
    Check Input/$1.img
    if [[ $Result == 0 ]];then
        Check Input/$1.transfer.list
        if [[ $Result == 1 ]];then
            python ./bin/sdat2img.py ./Input/$1.transfer.list ./Input/$1.new.dat ./Input/$1.img | grep Done
            Check Input/$1.img
            if [[ $Result == 1 ]];then
                echo "Done!!!!!!!" > ./bin/.create
            else
                echo "Fuck!!!Where's my $1.img?!!" > ./bin/.create
            fi
        else
            echo "Fuck!!!Where's my $1.transfer.list?!!" > ./bin/.create
        fi
    else
        rm -rf Input/$1.img
        UnpackDat $1
    fi
}

UnpackIMG(){
    Check Input/$1
    if [[ $Result == 0 ]];then
        python3 ./bin/imgextractor.py ./Input/$1.img ./Input/
        Check Input/$1
        if [[ $Result == 1 ]];then
            echo "Done!!!!!!!" > ./bin/.create
        else
            echo "Fuck!!!Where's my $1?!!" > ./bin/.create
        fi
    else
        rm -rf Input/$1
    fi
}

Kernel(){
    bash bin/AIK-Linux/cleanup.sh
    if [[ $1 == unpack ]];then
        Check IMG/boot
        if [[ $Result == 1 ]];then
            rm -rf IMG/boot
            mkdir IMG/boot
        else
            mkdir IMG/boot
            touch IMG/boot/imageinfo.txt
        fi        
        bash bin/AIK-Linux/unpackimg.sh > IMG/boot/imageinfo.txt
        Check bin/AIK-Linux/split_img
        if [[ $Result == 1 ]];then
            mv bin/AIK-Linux/split_img IMG/boot
            mv bin/AIK-Linux/ramdisk IMG/boot
            echo "Done!!!!!!!" > ./bin/.create
        else
            echo "Fuck!!!Where's my $1?!!" > ./bin/.create
        fi
    elif [[ $1 == repack ]];then
        bash bin/AIK-Linux/repackimg.sh  > /dev/null 2>&1
    fi
}

Payload(){
    python bin/extract_android_ota_payload.py Input/payload.bin Payload
    Check Payload/system.img
    if [[ $Result == 1 ]];then
        echo "Input/payload.bin --> Payload" > ./bin/.create
    else
        echo "Input/payload.bin extracted failed!!!" > ./bin/.create
    fi
}

Check './bin/.create' 
if [[ $Result == "0" ]];then
    mkdir Input
    mkdir IMG
    mkdir Payload
    touch ./bin/.create
fi

if [[ $1 == "--m" ]]; then 
    Menu
    read -p "Choose: " Choose
elif [[ $1 == "--c" ]]; then
    read -p "Are you sure you want to clean up work path?[y(es)/n(o)]" yn
    if [[ $yn == y ]];then
        Clean
        Info
    elif [[ $yn == yes ]];then
        Clean
        Info
    elif [[ $yn == n ]];then
        echo "OK!" > ./bin/.create
        Info
    elif [[ $yn == no ]];then
        echo "OK!" > ./bin/.create
        Info
    fi
else
    Usage
fi


if [[ $Choose == "1" ]];then
    Check Input/system.new.dat.br
    if [[ $Result == 1 ]];then
        UnpackBr system
        Info
    else
        echo "Input/[system.new.dat.br] not found!!!!!!" > ./bin/.create
        Info
    fi
elif [[ $Choose == "2" ]];then
    Check Input/system.new.dat
    if [[ $Result == 1 ]];then
        UnpackDat system
        Info
    else
        echo "Input/[system.new.dat] not found!!!!!!" > ./bin/.create
        Info
    fi
elif [[ $Choose == "3" ]];then
    Check Input/vendor.new.dat.br
    if [[ $Result == 1 ]];then
        UnpackBr vendor
        Info
    else
        echo "Input/[vendor.new.dat.br] not found!!!!!!" > ./bin/.create
        Info
    fi
elif [[ $Choose == "4" ]];then
    Check Input/vendor.new.dat
    if [[ $Result == 1 ]];then
        UnpackDat vendor
        Info
    else
        echo "Input/[vendor.new.dat] not found!!!!!!" > ./bin/.create
        Info
    fi
elif [[ $Choose == "5" ]];then
    Check Input/system.img
    if [[ $Result == 1 ]];then
        UnpackIMG system
        Info
    else
        echo "Input/[system.img] found!!!!!!" > ./bin/.create
        Info
    fi
elif [[ $Choose == "6" ]];then
    Check Input/vendor.img
    if [[ $Result == 1 ]];then
        UnpackIMG vendor
        Info
    else
        echo "Input/[vendor.img] not found!!!!!!" > ./bin/.create
        Info
    fi
elif [[ $Choose == "7" ]];then
    Check Input/boot.img
    if [[ $Result == 1 ]];then
        mv Input/boot.img bin/AIK-Linux
        Kernel unpack
        Info
    elif [[ $Result == 0 ]];then
        Check Input/recovery.img
        if [[ $Result == 1 ]];then
            mv Input/recovery.img bin/AIK-Linux
            Kernel unpack
            Info
        else
            echo "Input/[boot.img/recovery.img] not found!!!!!!" > ./bin/.create
            Info     
        fi
    fi
elif [[ $Choose == "8" ]];then
    Check Input/payload.bin
    if [[ $Result == 1 ]];then
        Payload
        Info
    elif [[ $Result == 0 ]];then
        echo "Input/payload.bin not found!!!!!!" > ./bin/.create
        Info
    fi
elif [[ $Choose == "9" ]];then
    AutoUnpack
elif [[ $Choose == "10" ]];then
    Clean
fi