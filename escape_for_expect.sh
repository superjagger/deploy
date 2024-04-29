#!/bin/bash

# 下载本地然后引用函数
# wget -O temp_script.sh https://raw.githubusercontent.com/superjagger/deploy/main/escape_for_expect.sh
# ./temp_script.sh
# rm ./temp_script.sh

# 转义 expect 中的特殊字符
function escape_for_expect() {
    input="$1"
    # 使用 sed 替换特定字符为它们的转义形式
    # 注意：这里只列出了一些常见的特殊字符，你可能需要添加更多
    adapted_password=$(
        echo $input |
            sed 's,\\,\\\\,g' |
            # sed "s/\,/\\\,/g" |
            # sed "s/{/\\\{/g" |
            # sed "s/*/\\\*/g" |
            # sed 's,/,\\\/,g' |
            # sed "s/=/\\\=/g" |
            # sed "s/\^/\\\^/g" |
            # sed 's,\@,\\\@,g' |
            # sed 's,\%,\\\%,g' |
            # sed 's,~,\\\~,g' |
            # sed 's,<,\\\<,g' |
            # sed 's,>,\\\>,g' |
            # sed 's,(,\\\(,g' |
            # sed 's,_,\\\_,g' |
            # sed 's,;,\\\;,g' |
            # sed 's,:,\\\:,g' |
            # sed "s/'/\\\'/g" |
            # sed "s/\./\\\./g" |
            # sed 's,!,\\\!,g' |
            # sed 's,|,\\\|,g' |
            # sed 's,?,\\\?,g' |
            # sed 's,+,\\\+,g' |
            # sed 's,],\\\],g' |
            # sed "s/\-/\\\-/g" |
            # sed 's,),\\\),g' |
            sed 's,",\\\",g' |
            sed "s/\[/\\\[/g" |
            sed "s/}/\\\}/g" |
            sed 's,\$,\\\$,g' |
            sed 's,`,\\\`,g'
    )
    echo "$adapted_password"
}
