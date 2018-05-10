# # v2
# FROM hello
# ENTRYPOINT mono hello.exe
#
# # v3
# FROM hello
# COPY hello3.exe /
# ENTRYPOINT mono hello3.exe

# # v4
# FROM hello
# COPY hello4.cs /
# RUN csc hello4.cs
# ENTRYPOINT mono hello4.exe

# #v5
# FROM hello
# COPY hello5.cs /
# RUN csc hello5.cs
# ENTRYPOINT ["mono", "hello5.exe"]

# v6
FROM hello
COPY hello6.cs /
RUN csc hello6.cs
ENV NAME World
ENTRYPOINT mono hello6.exe $NAME
# ENTRYPOINT ["sh", "-c" "mono hello6.exe $NAME"]
