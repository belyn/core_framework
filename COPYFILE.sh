# 清理文件
rm -rf *.a *make* *Make*

# copy需要打包的文件
cp -R ../3rd ../logs ../lualib ../script ../static ../docker ./

mkdir luaclib && mv *.so luaclib

# copy系统依赖文件
cp /usr/bin/msys-2.0.dll /usr/bin/msys-z.dll /usr/bin/msys-ssl-*.dll /usr/bin/msys-crypto-*.dll ./
