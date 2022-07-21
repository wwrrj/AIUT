#! /bin/bash

Check(){
if [[ -a $1 ]]; then
    Result='1'
else
    Result='0'
fi
}

IMGFiles="system system_ext product odm vendor"
BRFiles="system vendor system_ext product odm"
DATFiles="system vendor system_ext product odm"
BINFiles="payload"


Continue(){
    echo "Press any key to continue"
    read -n1
}

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
    echo "  1.分解new.dat.br"
    echo "  2.分解new.dat"
    echo "  3.分解img"
    echo "  4.分解super.img"
    echo "  5.分解boot/recovery.img"
    echo "  6.分解Payload.bin"
    echo "----------------------------------"
    echo "二.合并专区"
    echo "  11.打包new.dat.br"
    echo "  22.打包new.dat"
    echo "  33.打包img"
    echo "  44.打包super.img"
    echo "  55.打包boot/recovery.img"
    echo "  66.打包Payload.bin"
    echo "----------------------------------"
    echo "三.杂项"
    echo "  100.清理工具"
    echo "  200.解压刷机包"  
    echo "----------------------------------"
    read -p "Choose: " Choose

    if [[ $Choose == "1" ]];then
        if [[ $(ls Input | grep new.dat.br) != "" ]];then
            for b in $BRFiles; do
                if [[ -e Input/$b.new.dat.br ]];then
                    echo "[UnpackBr]: $b.new.dat.br"
                    UnpackBr $b
                    rm -rf Input/$b.new.dat.br
                fi
            done
        else
            echo "[UnpackBr]: *.new.dat.br not found!"
        fi
        Continue
        clear
        Menu
    elif [[ $Choose == "2" ]];then
        if [[ $(ls Input | grep -v br | grep new.dat) != "" ]];then
            for d in $DATFiles; do
                if [[ -e Input/$d.new.dat ]];then
                    echo "[UnpackDat]: $d.new.dat"
                    UnpackDat $d
                    rm -rf Input/$d.new.dat
                fi
            done
        else
            echo "[UnpackDat]: *.new.dat not found!"
        fi
        Continue
        clear
        Menu
    elif [[ $Choose == "3" ]];then
        if [[ $(ls Input | grep .img) != "" ]];then
            for i in $IMGFiles; do
                if [[ -e Input/$i.img ]];then
                    echo "[UnpackImg]: $i.img"
                    UnpackIMG $i
                    rm -rf Input/$i.img
                fi
            done
        else
            echo "[UnpackImg]: *.img not found!"
        fi
        Continue
        clear
        Menu
    elif [[ $Choose == "7" ]];then
        Check Input/boot.img
        if [[ $Result == 1 ]];then
            mv Input/boot.img bin/AIK-Linux
            Kernel unpack
        elif [[ $Result == 0 ]];then
            Check Input/recovery.img
            if [[ $Result == 1 ]];then
                mv Input/recovery.img bin/AIK-Linux
                Kernel unpack
            else
                echo "Input/[boot.img/recovery.img] not found!!!!!!"     
            fi
        fi
    elif [[ $Choose == "8" ]];then
        Check Input/payload.bin
        if [[ $Result == 1 ]];then
            Payload
            Info
        elif [[ $Result == 0 ]];then
            echo "Input/payload.bin not found!!!!!!"
        fi
    elif [[ $Choose == "100" ]];then
        Clean
    elif [[ $Choose == "200" ]];then
        AutoUnpack
    fi
}

AutoUnpack(){
    DecompressIMG(){
        for i in $IMGFiles; do
            if [[ -e Input/$i.img ]];then
                echo "[UnpackImg]: $i.img"
                UnpackIMG $i
            fi
        done
    }

    DecompressDAT(){
        for d in $DATFiles; do
            if [[ -e Input/$d.new.dat ]];then
                echo "[UnpackDat]: $d.new.dat"                
                UnpackDat $d
            fi
        done

        DecompressIMG
    }

    DecompressBR(){
        for b in $BRFiles; do
            if [[ -e Input/$b.new.dat.br ]];then
                echo "[UnpackBr]: $b.new.dat.br"
                UnpackBr $b
            fi
        done

        DecompressDAT
    }

    # DecompressBIN(){
    #    for a in $BINFiles; do
    #        if [[ -e Input/$a.bin ]];then
    #            echo "[UnpackBin]: $a.bin"
    #            Payload
    #        fi
    #    done
    #
    #    DecompressIMG
    #}

    UnpackZIP(){
        echo "[Unzip]: Working..."        
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
    
    if [[ $Unzip == "Done!" ]];then
        PayloadS
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
    echo "Done!"
}

UnpackBr(){
    Check Input/$1.new.dat
    if [[ $Result == 0 ]];then
        ./bin/brotli -d Input/$1.new.dat.br
        Check Input/$1.new.dat
        if [[ $Result == 1 ]];then
            echo "[UnpackBr]: Done!"
        else
            echo "[UnpackBr]: Failed!"
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
            python ./bin/sdat2img.py ./Input/$1.transfer.list ./Input/$1.new.dat ./Input/$1.img > /dev/null 2>&1
            Check Input/$1.img
            if [[ $Result == 1 ]];then
                echo "[UnpackDat]: Done!"
            else
                echo "[UnpackBat]: Failed!"
            fi
        fi
    else
        rm -rf Input/$1.img
        UnpackDat $1
    fi
}

UnpackIMG(){
    Check Input/$1
    if [[ $Result == 0 ]];then
        python3 ./bin/imgextractor.py ./Input/$1.img ./Input/ > /dev/null 2>&1
        Check Input/$1
        if [[ $Result == 1 ]];then
            echo "[UnpackImg]: Done!"
        else
            echo "[UnpackImg]: Failed!"
        fi
    else
        rm -rf Input/$1
        UnpackIMG $1
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
            echo "Done!!!!!!!"
        else
            echo "Fuck!!!Where's my $1?!!"
        fi
    elif [[ $1 == repack ]];then
        bash bin/AIK-Linux/repackimg.sh  > /dev/null 2>&1
    fi
}

Payload(){
    python bin/payload/payload.py Input/$1.bin Input
    Check Input/system.img
    if [[ $Result == 1 ]];then
        echo "Input/payload.bin --> Payload"
    else
        echo "Input/payload.bin extracted failed!!!"
    fi
}

Check './bin/.create' 
if [[ $Result == "0" ]];then
    mkdir Input
    mkdir IMG
    mkdir Payload
    touch ./bin/.create
fi

Menu