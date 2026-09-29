import os

with open('backend/src/main/java/com/futuretech/service/impl/StudentServiceImpl.java', 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

content = content.replace('request.getJoiningYear() + "?"" + request.getPassingYear()', 'request.getJoiningYear() + "-" + request.getPassingYear()')
content = content.replace('request.getJoiningYear() + "?"" + request.getPassingYear()', 'request.getJoiningYear() + "-" + request.getPassingYear()')
content = content.replace('?', '-')

with open('backend/src/main/java/com/futuretech/service/impl/StudentServiceImpl.java', 'w', encoding='utf-8') as f:
    f.write(content)

