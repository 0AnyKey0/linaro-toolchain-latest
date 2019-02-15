#!/bin/bash

git config --global user.email $GitHubMail
git config --global user.name $GitHubName
git config --global color.ui true

baseAddr="https://releases.linaro.org/components/toolchain/binaries"
branches="latest-4 latest-5 latest-6 latest-7"

for branch in $branches; do
    echo $branch >> /tmp/branch.txt
    tcBranch=$(cat '/tmp/branch.txt')
    git checkout "$tcBranch"
    curl -s "$baseAddr/$tcBranch/aarch64-linux-gnu/" | grep "x86_64_aarch64-linux-gnu.tar.xz" | sort | cut -d , -f3 | tail -n 2 | head -n 1 | awk '{print substr($1,2)}' | sed 's/....$//g' >> /tmp/latest-file-name.txt
    fileName=$(cat '/tmp/latest-file-name.txt')
    fileAddr=$baseAddr/$tcBranch/$(cat '/tmp/release-file.txt')
    wget -q --show-progress -P /tmp/ $fileAddr
    md5sum /tmp/$fileName >> /tmp/latest-archive.md5
    if cmp -s "/tmp/latest-archive.md5" "release-archive.md5"; then
        echo "Files are Identical. No need to update"
    else
        cd ..
        rm -rf 'linaro-toolchain-latest/*'
        tar -xJvf /tmp/$fileName --directory 'linaro-toolchain-latest/'
        md5sum /tmp/$fileName >> 'linaro-toolchain-latest/release-archive.md5'
        cd linaro-toolchain-latest/
        git add -A .
        git commit -m "Update Release at $(date +%Y%m%d-%H%M)"
        ##git push origin ${TC_Branch}
        git push -q https://$GitOAUTHToken@github.com/rokibhasansagar/linaro-toolchain-latest.git HEAD:$branch
    fi
done
