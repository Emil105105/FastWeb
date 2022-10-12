from logging import basicConfig as fw_log_basicConfig, info as fw_log_info, INFO as FW_LOG_INFO
from datetime import timedelta as fw_timedelta
from hashlib import sha3_256 as fw_sha3_256
from os.path import exists as fw_exists
from os import urandom as fw_urandom


app = flask.Flask(__name__)

if not fw_exists('vaY7PLX2ok1A'):
    with open('vaY7PLX2ok1A', 'wb') as fw_file:
        fw_file.write(fw_urandom(32))
with open('vaY7PLX2ok1A', 'rb') as fw_file:
    app.secret_key = fw_file.read()

fw_log_basicConfig(filename='main.log', format='%(asctime)s\t%(message)s', datefmt='%Y-%m-%d_%H-%M-%S',
                   level=FW_LOG_INFO)

FW_HTTP_METHODS = ['GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'CONNECT', 'OPTIONS', 'TRACE', 'PATCH']


def fw_sha256(fw_bytes):
    fw_h = fw_sha3_256()
    fw_h.update(fw_bytes)
    return fw_h.digest()


@app.before_request
def fw_before_request():
    flask.session.permanent = True
    app.permanent_session_lifetime = fw_timedelta(days=%%COOKIE_MAX_AGE%%)
    if %%HASH_IP%%:
        fw_log_info(f'{fw_sha256(flask.request.access_route[-1].encode()).hex()}\t{flask.request.method}\t'
                    f'{flask.request.full_path}\t{flask.request.user_agent.string}')
    else:
        fw_log_info(f'{flask.request.access_route[-1]}\t{flask.request.method}\t{flask.request.full_path}\t'
                    f'{flask.request.user_agent.string}')
