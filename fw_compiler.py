#!/usr/bin/env python3

# exit(4) illegal file name
# exit(5) _ or _.* file alongside site.py
# exit(6) directory alongside path.py
# exit(7) static file alongside path.py
# exit(8) multiple _ or _.* files
# exit(9) syntax error


from sys import argv, exit
from json import load
from os.path import join, isdir, basename, dirname
from os import listdir


def main(arguments):
    if len(arguments) < 2:
        exit(1)
    project_path = arguments[1]
    with open(f'{project_path}/config.json', 'r') as f:
        config = load(f)
    path = f'/var/FastWeb/{config["name"]}'
    out = '#!/usr/bin/env python3\n'
    with open(f'{project_path}/global.py', 'r') as f:
        out += f.read() + '\n'
    if '\nimport flask\n' not in out:
        out += 'import flask\n'
    with open('/opt/FastWeb/main_components.py', 'r') as f:
        content = f.read()
    content = content.replace('%%COOKIE_MAX_AGE%%', config['cookie_max_age'])
    content = content.replace('%%HASH_IP%%', config['hash_ips'])
    out += '\n' + content + '\n'
    files = []
    paths = listdir(join(project_path, 'sites'))
    if 'path.py' in paths:
        for file_name in paths:
            if isdir(join(project_path, 'sites', file_name)):
                exit(6)
            if file_name[0] != '_' and file_name != 'path.py':
                exit(7)
    if 'site.py' in paths:
        for file_name in paths:
            if file_name == '_' or file_name.startswith('_.'):
                exit(5)
    underscore_count = 0
    for file_name in paths:
        if file_name == '_' or file_name.startswith('_.'):
            underscore_count += 1
    if underscore_count > 1:
        exit(8)
    while len(paths) > 0:
        file = paths[0]
        del paths[0]
        file_path = join(project_path, 'sites', file)
        if ('__' in file) or (' ' in file):
            exit(4)
        if isdir(file_path):
            list_dir = listdir(file_path)
            if 'path.py' in list_dir:
                for file_name in list_dir:
                    if isdir(join(file_path, file_name)):
                        exit(6)
                    if file_name[0] != '_' and file_name != 'path.py':
                        exit(7)
            if 'site.py' in list_dir:
                for file_name in list_dir:
                    if file_name == '_' or file_name.startswith('_.'):
                        exit(5)
            underscore_count = 0
            for file_name in list_dir:
                if file_name == '_' or file_name.startswith('_.'):
                    underscore_count += 1
            if underscore_count > 1:
                exit(8)
            for i in list_dir:
                paths.append(join(file, i))
        else:
            files.append(file)
    for file in files:
        if file[0] != '/':
            file = '/' + file
        file_name = basename(file)
        if file_name == '_' or file_name.startswith('_.'):
            new_name = join(path, 'templates', file[1:].replace('/', '__'))
            out += f"\n@app.route('{dirname(file)}', methods=FW_HTTP_METHODS)\ndef fw_site_" \
                   f"{dirname(file)[1:].replace('/', '__')}():\n    return flask.send_from_directory('{new_name}')"
            with open(join(project_path, 'sites', file[1:]), 'rb') as old_f:
                with open(join(path, 'templates', new_name), 'wb') as new_f:
                    new_f.write(old_f.read())
        elif file_name == 'site.py':
            out += f"\n@app.route('{dirname(file)}', methods=FW_HTTP_METHODS)\ndef fw_site_" \
                   f"{dirname(file)[1:].replace('/', '__')}():\n"
            with open(join(project_path, 'sites', file[1:]), 'r') as f:
                content = f.read()
            if content[0] in ['\n', ' ']:
                exit(9)
            content = content.replace('\n', '\n    ')
            content = content.replace('file(', f"'{dirname(file)[1:].replace('/', '__')}__' + str(")
            out += content + '\n'
        elif file_name == 'path.py':
            out += f"\n@app.route('{join(dirname(file), '<path:SITE_PATH>')}', methods=FW_HTTP_METHODS)\ndef fw_site_" \
                   f"{dirname(file)[1:].replace('/', '__')}(SITE_PATH):\n"
            with open(join(project_path, 'sites', file[1:]), 'r') as f:
                content = f.read()
            if content[0] in ['\n', ' ']:
                exit(9)
            content = content.replace('\n', '\n    ')
            content = content.replace('file(', f"'{dirname(file)[1:].replace('/', '__')}__' + str(")
            out += content + '\n'
        elif file_name.startswith('_'):
            new_name = join(path, 'templates', file[1:].replace('/', '__'))
            with open(join(project_path, 'sites', file[1:]), 'rb') as old_f:
                with open(join(path, 'templates', new_name), 'wb') as new_f:
                    new_f.write(old_f.read())
        else:
            new_name = join(path, 'templates', file[1:].replace('/', '__'))
            out += f"\n@app.route('{file}', methods=FW_HTTP_METHODS)\ndef fw_site_" \
                   f"{file[1:].replace('/', '__')}():\n    return flask.send_from_directory({new_name})"
            with open(join(project_path, 'sites', file[1:]), 'rb') as old_f:
                with open(join(path, 'templates', new_name), 'wb') as new_f:
                    new_f.write(old_f.read())
    with open(join(path, 'main.py'), 'w') as f:
        f.write(out + '\n')


if __name__ == '__main__':
    main(argv)
