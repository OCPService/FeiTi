#coding:utf-8
from BaseHTTPServer import BaseHTTPRequestHandler
from SocketServer import ThreadingMixIn, TCPServer
from multiprocessing.pool import ThreadPool

import re
import ssl
import json
import urllib2
import hashlib
import random
import datetime
import commands
import threading

MUTEX = threading.Lock()

class Utility(object):
    DATE_FORMAT_STANDARD = '%Y-%m-%d %H:%M:%S'
    DATE_FORMAT_FOR_ID_USAGE = '%Y%m%d%H%M%S'
    DATE_FORMAT_FOR_ID_USAGE_MIN = '%Y%m%d%H%M%S%f'
    DATE_FORMAT_FOR_ID_USAGE_ONLY_DATE = '%Y%m%d'

    # String Utility
    @staticmethod
    def is_str(value):
        return value and isinstance(value, str)

    @staticmethod
    def is_solid_str(value):
        return Utility.is_str(value) and len(value) > 0

    @staticmethod
    def is_safe_str(value):
        is_safe = Utility.is_solid_str(value)
        if is_safe:
            for c in value:
                if c in ",./<>?;:\'\"\[\{\]\}`~!@#$%^&*()":
                    is_safe = False
                    break
        return is_safe

    @staticmethod
    def is_email_address(value):
        return True if re.match('[^@]+@[^@]+\.[^@]+', value) else False

    @staticmethod
    def to_md5(value):
        m = hashlib.md5()
        m.update(value)
        return m.hexdigest()

    @staticmethod
    def to_int(value):
        try:
            return int(value)
        except:
            pass
        return None

    @staticmethod
    def format_unicode_str(value, *args):
        params = ()
        for arg in args:
            if isinstance(arg, unicode):
                params = params + (arg.encode('utf-8'), )
            else:
                params = params + (arg, )

        return value.format(*params)

    # Int Utility
    @staticmethod
    def is_odd(value):
        if isinstance(value, int):
            return value % 2 == 1
        return False

    # Random Utility
    @staticmethod
    def get_random_int(min_number, max_number):
        return random.randint(min_number, max_number)

    # Datetime Utility
    @staticmethod
    def hour_to_second(value):
        if isinstance(value, int) and value > 0:
            return value * 3600
        return 0

    @staticmethod
    def get_utc_date():
        return datetime.datetime.utcnow()

    @staticmethod
    def is_datetime(value):
        return isinstance(value, datetime.datetime)

    @staticmethod
    def str_to_date(value, date_format=None):
        if Utility.is_solid_str(value):
            if Utility.is_solid_str(date_format):
                return datetime.datetime.strptime(value, date_format)
            else:
                return datetime.datetime.strptime(value, Utility.DATE_FORMAT_STANDARD)
        return None

    @staticmethod
    def date_to_str(value, date_format=None):
        if Utility.is_datetime(value):
            if Utility.is_solid_str(date_format):
                return value.strftime(date_format)
            else:
                return value.strftime(Utility.DATE_FORMAT_STANDARD)
        return None

    @staticmethod
    def is_solid_dict(value):
        return isinstance(value, dict) and len(value) > 0

class LinuxCommand(object):
    @staticmethod
    def execute_read(cmd):
        if Utility.is_solid_str(cmd):
            (status, output) = commands.getstatusoutput(cmd)
            if status == 0:
                return output
        return None

    @staticmethod
    def execute_query(cmd):
        if Utility.is_solid_str(cmd):
            (status, output) = commands.getstatusoutput(cmd)
            return status == 0
        return False

class Configurations(object):

    _commands = {
        'get_configurations': "cat /etc/feiti/console/configurations"
    }

    @staticmethod
    def is_valid_configurations(configurations):
        return Utility.is_solid_dict(configurations) and \
               'servers' in configurations and isinstance(configurations['servers'], list) and \
               'iap_ids' in configurations and isinstance(configurations['iap_ids'], list) and \
               'ad' in configurations and isinstance(configurations['ad'], dict) and \
               'provider' in configurations['ad'] and Advertise.is_valid_provider(configurations['ad']['provider']) and \
               'banner_id' in configurations['ad'] and Utility.is_solid_str(configurations['ad']['banner_id']) and \
               'inter_ad_id' in configurations['ad'] and Utility.is_solid_str(configurations['ad']['inter_ad_id']) and \
               'notifications' in configurations and isinstance(configurations['notifications'], list) and \
               'support_mail' in configurations

    @staticmethod
    def get_configurations():
        result = LinuxCommand.execute_read(Configurations._commands['get_configurations'])
        if result:
            try:
                configurations = eval(result)
                if Configurations.is_valid_configurations(configurations):
                    servers_hash = Utility.to_md5(Utility.format_unicode_str('{0}', configurations['servers']))
                    notifications_hash = Utility.to_md5('{0}'.format(configurations['notifications']))
                    configurations['hash'] = {'server': servers_hash,
                                              'notification': notifications_hash}
                    return configurations
            except:
                pass
        return None

    @staticmethod
    def get_system_allowed_ips():
        result = LinuxCommand.execute_read(Configurations._commands['get_system_allowed_ips'])

class Token(object):
    _user_id_encrypt_maps = {
        'a': {'0': 'e', '1': '0', '2': '5', '3': '6', '4': 'f', '5': '8', '6': 'b', '7': 'a', '8': '9', '9': '1'},
        'b': {'0': 'f', '1': '8', '2': '3', '3': 'e', '4': 'c', '5': '9', '6': '1', '7': '4', '8': '0', '9': '7'},
        'c': {'0': '5', '1': '1', '2': '9', '3': '0', '4': '7', '5': '8', '6': 'c', '7': '4', '8': 'a', '9': 'd'},
        'd': {'0': 'f', '1': 'a', '2': '0', '3': '1', '4': '4', '5': '5', '6': '6', '7': '3', '8': 'e', '9': '9'},
        'e': {'0': 'e', '1': '6', '2': '3', '3': 'c', '4': '4', '5': '0', '6': '7', '7': 'd', '8': '2', '9': '5'},
        'f': {'0': '4', '1': 'e', '2': '8', '3': 'd', '4': '0', '5': '9', '6': 'c', '7': '6', '8': 'a', '9': '1'},
        '0': {'0': '4', '1': '0', '2': '2', '3': 'c', '4': '1', '5': 'a', '6': '9', '7': '6', '8': '8', '9': '3'},
        '1': {'0': 'e', '1': 'a', '2': '0', '3': '5', '4': 'b', '5': '9', '6': '1', '7': '7', '8': '8', '9': '2'},
        '2': {'0': '1', '1': 'd', '2': 'f', '3': '6', '4': '2', '5': 'a', '6': '4', '7': '7', '8': '5', '9': 'e'},
        '3': {'0': '5', '1': '3', '2': '1', '3': '0', '4': '4', '5': 'f', '6': 'c', '7': '9', '8': '6', '9': '2'},
        '4': {'0': '7', '1': 'a', '2': '5', '3': '4', '4': '1', '5': 'f', '6': 'c', '7': 'd', '8': 'e', '9': '3'},
        '5': {'0': '3', '1': 'c', '2': 'f', '3': '4', '4': '9', '5': 'a', '6': '2', '7': 'e', '8': '8', '9': '1'},
        '6': {'0': 'd', '1': '9', '2': '7', '3': '1', '4': '8', '5': '5', '6': '0', '7': '6', '8': 'e', '9': '4'},
        '7': {'0': 'a', '1': 'f', '2': '7', '3': 'e', '4': '9', '5': '0', '6': '8', '7': '5', '8': '3', '9': 'd'},
        '8': {'0': 'd', '1': 'a', '2': 'e', '3': '7', '4': '3', '5': '2', '6': '9', '7': '1', '8': '4', '9': 'b'},
        '9': {'0': '1', '1': '4', '2': 'd', '3': '9', '4': '6', '5': '2', '6': 'f', '7': '0', '8': '8', '9': '5'}
    }

    _user_id_decrypt_maps = {
        'a': {'e': '0', '0': '1', '5': '2', '6': '3', 'f': '4', '8': '5', 'b': '6', 'a': '7', '9': '8', '1': '9'},
        'b': {'f': '0', '8': '1', '3': '2', 'e': '3', 'c': '4', '9': '5', '1': '6', '4': '7', '0': '8', '7': '9'},
        'c': {'5': '0', '1': '1', '9': '2', '0': '3', '7': '4', '8': '5', 'c': '6', '4': '7', 'a': '8', 'd': '9'},
        'd': {'f': '0', 'a': '1', '0': '2', '1': '3', '4': '4', '5': '5', '6': '6', '3': '7', 'e': '8', '9': '9'},
        'e': {'e': '0', '6': '1', '3': '2', 'c': '3', '4': '4', '0': '5', '7': '6', 'd': '7', '2': '8', '5': '9'},
        'f': {'4': '0', 'e': '1', '8': '2', 'd': '3', '0': '4', '9': '5', 'c': '6', '6': '7', 'a': '8', '1': '9'},
        '0': {'4': '0', '0': '1', '2': '2', 'c': '3', '1': '4', 'a': '5', '9': '6', '6': '7', '8': '8', '3': '9'},
        '1': {'e': '0', 'a': '1', '0': '2', '5': '3', 'b': '4', '9': '5', '1': '6', '7': '7', '8': '8', '2': '9'},
        '2': {'1': '0', 'd': '1', 'f': '2', '6': '3', '2': '4', 'a': '5', '4': '6', '7': '7', '5': '8', 'e': '9'},
        '3': {'5': '0', '3': '1', '1': '2', '0': '3', '4': '4', 'f': '5', 'c': '6', '9': '7', '6': '8', '2': '9'},
        '4': {'7': '0', 'a': '1', '5': '2', '4': '3', '1': '4', 'f': '5', 'c': '6', 'd': '7', 'e': '8', '3': '9'},
        '5': {'3': '0', 'c': '1', 'f': '2', '4': '3', '9': '4', 'a': '5', '2': '6', 'e': '7', '8': '8', '1': '9'},
        '6': {'d': '0', '9': '1', '7': '2', '1': '3', '8': '4', '5': '5', '0': '6', '6': '7', 'e': '8', '4': '9'},
        '7': {'a': '0', 'f': '1', '7': '2', 'e': '3', '9': '4', '0': '5', '8': '6', '5': '7', '3': '8', 'd': '9'},
        '8': {'d': '0', 'a': '1', 'e': '2', '7': '3', '3': '4', '2': '5', '9': '6', '1': '7', '4': '8', 'b': '9'},
        '9': {'1': '0', '4': '1', 'd': '2', '9': '3', '6': '4', '2': '5', 'f': '6', '0': '7', '8': '8', '5': '9'}
    }

    @staticmethod
    def user_id_to_token(user_id, expire_duration=10800):
        if Utility.is_solid_str(user_id) and len(user_id) == 20 and user_id.isdigit():
            user_id_map_key = random.sample('abcdef0123456789', 1)[0]
            user_id_map = Token._user_id_encrypt_maps[user_id_map_key]
            mapped_user_id = ''
            for c in user_id:
                mapped_user_id += user_id_map[c]

            expire_date = Utility.get_utc_date() + datetime.timedelta(0, expire_duration)
            expire = Utility.date_to_str(expire_date, Utility.DATE_FORMAT_FOR_ID_USAGE)
            expire_map_key = random.sample('abcdef0123456789', 1)[0]
            expire_map = Token._user_id_encrypt_maps[expire_map_key]
            mapped_expire = ''
            for c in expire:
                mapped_expire += expire_map[c]

            verify_code = Utility.to_md5('{0}{1}'.format(user_id, expire))
            prefix_verify_code = verify_code[0:16]
            surfix_verify_code = verify_code[16:32]

            user_token = '{0}{1}{2}{3}{4}{5}'.format(prefix_verify_code, user_id_map_key, mapped_user_id, expire_map_key, mapped_expire, surfix_verify_code)
            if user_token and len(user_token) == 68:
                return user_token

        return None

    @staticmethod
    def token_to_user_id(user_token, check_expire=True):
        if Utility.is_solid_str(user_token) and len(user_token) == 68:
            user_id_map_key = user_token[16]
            user_id_map = Token._user_id_decrypt_maps[user_id_map_key]
            mapped_user_id = user_token[17:37]
            user_id = ''
            for c in mapped_user_id:
                user_id += user_id_map[c]

            expire_map_key = user_token[37]
            expire_map = Token._user_id_decrypt_maps[expire_map_key]
            mapped_expire = user_token[38:52]
            expire_str = ''
            for c in mapped_expire:
                expire_str += expire_map[c]

            verify_code = '{0}{1}'.format(user_token[0:16], user_token[52:68])
            actual_code = Utility.to_md5('{0}{1}'.format(user_id, expire_str))

            if verify_code == actual_code and user_id and user_id.isdigit():
                if check_expire:
                    expire = Utility.str_to_date(expire_str, Utility.DATE_FORMAT_FOR_ID_USAGE)
                    now = Utility.get_utc_date()
                    if now > expire:
                        return -1
                return user_id
        return None

class User(object):
    TYPE_FREE = 1
    TYPE_VIP = 8

    UPDATE_EXPIRE_SECONDS_DAY = 86400

    _commands = {
        'get_user_by_user_id': "cat /etc/feiti/console/user/* | grep 'user_id:{0}|'",
        'get_user_by_account': "cat /etc/feiti/console/user/* | grep '|account_md5:{0}'",
        'get_user_by_email': "cat /etc/feiti/console/user/* | grep '|email_md5:{0}'",
        'get_user_by_hash': "cat /etc/feiti/console/user/* | grep '|hash:{0}'",
        'get_user_by_uuid': "cat /etc/feiti/console/user/* | grep '|uuid_md5:{0}'",
        'get_user_by_ifna': "cat /etc/feiti/console/user/* | grep '|ifna_md5:{0}'",
        'get_user_by_duid': "cat /etc/feiti/console/user/* | grep '|duid_md5:{0}'",
        'get_user_by_md5': "cat /etc/feiti/console/user/* | grep '|{0}_md5:{1}'",
        'save_user': "echo '{0}' > /etc/feiti/console/user/{1}",
    }

    @staticmethod
    def new_user_id():
        return Utility.date_to_str(Utility.get_utc_date(), Utility.DATE_FORMAT_FOR_ID_USAGE_MIN)

    @staticmethod
    def new_password():
        return ''.join(random.sample('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', 6))

    '''
    @staticmethod
    def new_guest_user(ip, uuid, ifna, duid):
        user_id = User.new_user_id()
        account = 'g{0}'.format(Utility.get_random_int(1000000, 9999999))
        while User.get_user_by_account(account):
            account = 'g{0}'.format(Utility.get_random_int(1000000, 9999999))
        password = User.new_password()
        duration_time = datetime.timedelta(0, Utility.hour_to_second(Utility.get_random_int(1, 3)))
        expire = Utility.get_utc_date() + duration_time
        points = 0
        account_md5 = Utility.to_md5(account)
        uuid_md5 = Utility.to_md5(uuid)
        ifna_md5 = Utility.to_md5(ifna)
        duid_md5 = Utility.to_md5(duid)
        return {
            'user_id': user_id,
            'account': account,
            'password': password,
            'kind': User.TYPE_FREE,
            'expire': expire,
            'points': points,
            'ip': ip,
            'account_md5': account_md5,
            'uuid_md5': uuid_md5,
            'ifna_md5': ifna_md5,
            'duid_md5': duid_md5,
        }
    '''

    @staticmethod
    def new_guest_user(ip, extras):
        if Utility.is_solid_dict(extras):
            user_id = User.new_user_id()
            account = 'g{0}'.format(Utility.get_random_int(1000000, 9999999))
            while User.get_user_by_account(account):
                account = 'g{0}'.format(Utility.get_random_int(1000000, 9999999))
            duration_time = datetime.timedelta(0, Utility.hour_to_second(Utility.get_random_int(1, 3)))
            expire = Utility.get_utc_date() + duration_time
            user = {
                'user_id': user_id,
                'account': account,
                'password': User.new_password(),
                'kind': User.TYPE_FREE,
                'expire': expire,
                'points': 0,
                'ip': ip,
                'account_md5': Utility.to_md5(account)
            }

            for key in extras:
                user['{0}_md5'.format(key)] = Utility.to_md5(extras[key])

            return user

        return None

    @staticmethod
    def is_valid_user(user):
        is_generic_valid = Utility.is_solid_dict(user) and \
                           'user_id' in user and len(user['user_id']) == 20 and \
                           'account' in user and len(user['account']) == 8 and \
                           'password' in user and len(user['password']) == 32 and \
                           'kind' in user and (user['kind'] == User.TYPE_FREE or user['kind'] == User.TYPE_VIP) and \
                           'expire' in user and isinstance(user['expire'], datetime.datetime) and \
                           'points' in user and isinstance(user['points'], int) and \
                           'ip' in user and user['ip'] and \
                           'account_md5' in user and len(user['account_md5']) == 32 and \
                           'hash' in user and len(user['hash']) == 32

        is_ios_valid = 'uuid_md5' in user and len(user['uuid_md5']) == 32 and \
                       'ifna_md5' in user and len(user['ifna_md5']) == 32 and \
                       'duid_md5' in user and len(user['duid_md5']) == 32

        is_mac_valid = 'serial_md5' in user and len(user['serial_md5']) == 32

        return is_generic_valid and (is_ios_valid or is_mac_valid)

    @staticmethod
    def is_user_expired(user):
        if User.is_valid_user(user):
            now = Utility.get_utc_date()
            return now > user['expire']
        return True

    @staticmethod
    def is_email_verified_user(user):
        return 'email' in user and len(user['email']) > 0 and 'email_md5' in user and len(user['email_md5']) == 32

    @staticmethod
    def get_user_by_uuid(uuid):
        if Utility.is_solid_str(uuid):
            uuid_md5 = Utility.to_md5(uuid)
            result = LinuxCommand.execute_read(User._commands['get_user_by_uuid'].format(uuid_md5))
            if result:
                return User.user_data_to_dict(result)
        return None

    @staticmethod
    def get_user_by_ifna(ifna):
        if Utility.is_solid_str(ifna):
            ifna_md5 = Utility.to_md5(ifna)
            result = LinuxCommand.execute_read(User._commands['get_user_by_ifna'].format(ifna_md5))
            if result:
                return User.user_data_to_dict(result)
        return None

    @staticmethod
    def get_user_by_duid(duid):
        if Utility.is_solid_str(duid):
            duid_md5 = Utility.to_md5(duid)
            result = LinuxCommand.execute_read(User._commands['get_user_by_duid'].format(duid_md5))
            if result:
                return User.user_data_to_dict(result)
        return None

    @staticmethod
    def get_user_by_md5(key, value):
        if Utility.is_solid_str(key) and Utility.is_solid_str(value):
            md5_value = Utility.to_md5(value)
            command = User._commands['get_user_by_md5'].format(key, md5_value)
            result = LinuxCommand.execute_read(command)
            if result:
                return User.user_data_to_dict(result)

        return None

    @staticmethod
    def get_user_by_user_id(user_id):
        if Utility.is_solid_str(user_id):
            result = LinuxCommand.execute_read(User._commands['get_user_by_user_id'].format(user_id))
            if result:
                return User.user_data_to_dict(result)
        return None

    @staticmethod
    def get_user_by_email(email):
        if Utility.is_solid_str(email):
            email_md5 = Utility.to_md5(email)
            result = LinuxCommand.execute_read(User._commands['get_user_by_email'].format(email_md5))
            if result:
                return User.user_data_to_dict(result)
        return None

    @staticmethod
    def get_user_by_account(account):
        if Utility.is_solid_str(account):
            account_md5 = Utility.to_md5(account)
            result = LinuxCommand.execute_read(User._commands['get_user_by_account'].format(account_md5))
            if result:
                return User.user_data_to_dict(result)
        return None

    @staticmethod
    def get_user_by_hash(value):
        if Utility.is_safe_str(value):
            result = LinuxCommand.execute_read(User._commands['get_user_by_hash'].format(value))
            if result:
                return User.user_data_to_dict(result)
        return None

    @staticmethod
    def increase_user_points(user, points):
        if user and User.is_valid_user(user) and isinstance(points, int) and points > 0:
            user['points'] += points
            return user
        return None

    @staticmethod
    def decrease_user_points(user, points):
        if user and User.is_valid_user(user) and isinstance(points, int) and points > 0:
            user['points'] -= points
            return user
        return None

    @staticmethod
    def update_password(user, password):
        if user and User.is_valid_user(user) and Utility.is_solid_str(password):
            user['password'] = Utility.to_md5(password)
            user['hash'] = Utility.to_md5('{0}{1}'.format(user['user_id'], user['password']))
            return user
        return None

    @staticmethod
    def update_user_kind_expire(user, kind, seconds):
        if user and isinstance(seconds, int) and seconds > 0 and (kind == User.TYPE_FREE or kind == User.TYPE_VIP):
            duration_time = datetime.timedelta(0, seconds)
            expire = Utility.get_utc_date() + duration_time
            user['expire'] = expire
            user['kind'] = kind
            return user
        return None

    @staticmethod
    def save_user(user):
        user_data = User.dict_to_user_data(user)
        if user_data:
            return LinuxCommand.execute_query(User._commands['save_user'].format(user_data, user['user_id']))
        return False

    @staticmethod
    def user_data_to_dict(data):
        if Utility.is_solid_str(data) and len(data.split('\n')) == 1:
            output = {}
            items = data.split('|')
            for item in items:
                if Utility.is_solid_str(item) and ':' in item:
                    pair = item.split(':')
                    if pair[0] == 'expire':
                        output[pair[0]] = Utility.str_to_date(pair[1], Utility.DATE_FORMAT_FOR_ID_USAGE)
                    elif pair[0] == 'points' or pair[0] == 'kind':
                        output[pair[0]] = int(pair[1])
                    else:
                        output[pair[0]] = pair[1]
            if User.is_valid_user(output):
                return output
        return None

    @staticmethod
    def dict_to_user_data(user):
        if User.is_valid_user(user):
            user_data = 'user_id:{0}|account:{1}|email:{2}|password:{3}|kind:{4}|expire:{5}|points:{6}|ip:{7}|account_md5:{8}'. \
                        format(user['user_id'], user['account'], user['password'], user['email'], user['kind'],
                               Utility.date_to_str(user['expire'], Utility.DATE_FORMAT_FOR_ID_USAGE), user['points'],
                               user['ip'],
                               user['account_md5'])
            if User.is_email_verified_user(user):
                user_data = 'user_id:{0}|account:{1}|email:{2}|password:{3}|kind:{4}|expire:{5}|points:{6}|ip:{7}|account_md5:{8}|email_md5:{9}'.\
                            format(user['user_id'], user['account'], user['password'], user['email'], user['kind'],
                                   Utility.date_to_str(user['expire'], Utility.DATE_FORMAT_FOR_ID_USAGE), user['points'],
                                   user['ip'],
                                   user['account_md5'],
                                   user['email_md5'])
                return 'user_id:{0}|account:{1}|email:{2}|password:{3}|kind:{4}|expire:{5}|points:{6}|ip:{7}|account_md5:{8}|email_md5:{9}|uuid_md5:{10}|ifna_md5:{11}|duid_md5:{12}|hash:{13}'. \
                    format(user['user_id'], user['account'], user['password'], user['email'], user['kind'],
                           Utility.date_to_str(user['expire'], Utility.DATE_FORMAT_FOR_ID_USAGE), user['points'],
                           user['ip'],
                           user['account_md5'],
                           user['email_md5'],
                           user['uuid_md5'],
                           user['ifna_md5'],
                           user['duid_md5'],
                           user['hash'])
            else:
                user_data = 'user_id:{0}|account:{1}|email:{2}|password:{3}|kind:{4}|expire:{5}|points:{6}|ip:{7}|account_md5:{8}'. \
                            format(user['user_id'], user['account'], user['password'], user['email'], user['kind'],
                                   Utility.date_to_str(user['expire'], Utility.DATE_FORMAT_FOR_ID_USAGE), user['points'],
                                   user['ip'],
                                   user['account_md5'])
                return 'user_id:{0}|account:{1}|password:{2}|kind:{3}|expire:{4}|points:{5}|ip:{6}|account_md5:{7}|uuid_md5:{8}|ifna_md5:{9}|duid_md5:{10}|hash:{11}'. \
                    format(user['user_id'], user['account'], user['password'], user['kind'],
                           Utility.date_to_str(user['expire'], Utility.DATE_FORMAT_FOR_ID_USAGE), user['points'],
                           user['ip'],
                           user['account_md5'],
                           user['uuid_md5'],
                           user['ifna_md5'],
                           user['duid_md5'],
                           user['hash'])
        return None

class Tracking(object):
    _commands = {'log_refresh': "echo 'user_id:{0}|ip:{1}|date:{2}' >> /etc/feiti/console/track/refresh"
                 }

    @staticmethod
    def log_refresh(user, ip):
        if User.is_valid_user(user):
            now = Utility.date_to_str(Utility.get_utc_date(), Utility.DATE_FORMAT_FOR_ID_USAGE)
            return LinuxCommand.execute_query(Tracking._commands['log_refresh'].format(user['user_id'], ip, now))
        return False

class IAP(object):
    PRODUCT_ID_VIP_ONE = 'com.feiti.feitiservice.vip.one.month'
    PRODUCT_ID_VIP_THREE = 'com.feiti.feitiservice.vip.three.month'
    PRODUCT_ID_VIP_SIX = 'com.feiti.feitiservice.vip.six.month'
    PRODUCT_ID_VIP_TWELVE = 'com.feiti.feitiservice.vip.twelve.month'

    RECEIPT_VERIFY_URL_SANDBOX = 'https://sandbox.itunes.apple.com/verifyReceipt'
    RECEIPT_VERIFY_URL = 'https://buy.itunes.apple.com/verifyReceipt'

    BUNDLE_ID = 'com.feiti.feitiservice'

    PURCHASE_DATE_FORMAT = '%Y-%m-%d %H:%M:%S Etc/GMT'

    _commands = {
        'log_receipt': "echo '{0}' > /etc/feiti/console/iap/receipt_log/{1}-{2}-{3}",
        'log_purchase': "echo '{0}' > /etc/feiti/console/iap/purchase_log/{1}-{2}-{3}",
        'is_receipt_exist': "ls /etc/feiti/console/iap/receipt_log/*-{0}-*",
        'is_purchase_exist': "ls /etc/feiti/console/iap/purchase_log/*-{0}-*"
    }

    @staticmethod
    def log_purchase(user_id, receipt):
        receipt_md5 = Utility.to_md5(receipt)
        now = Utility.date_to_str(Utility.get_utc_date(), Utility.DATE_FORMAT_FOR_ID_USAGE)
        return LinuxCommand.execute_query(IAP._commands['log_purchase'].format(receipt, user_id, receipt_md5, now))

    @staticmethod
    def log_receipt(user_id, receipt):
        receipt_md5 = Utility.to_md5(receipt)
        now = Utility.date_to_str(Utility.get_utc_date(), Utility.DATE_FORMAT_FOR_ID_USAGE)
        return LinuxCommand.execute_query(IAP._commands['log_receipt'].format(receipt, user_id, receipt_md5, now))

    @staticmethod
    def is_receipt_exist(receipt):
        receipt_md5 = Utility.to_md5(receipt)
        result = LinuxCommand.execute_read(IAP._commands['is_receipt_exist'].format(receipt_md5))
        return Utility.is_solid_str(result) and len(result) == 68

    @staticmethod
    def is_purchase_exist(receipt):
        receipt_md5 = Utility.to_md5(receipt)
        result = LinuxCommand.execute_read(IAP._commands['is_purchase_exist'].format(receipt_md5))
        return Utility.is_solid_str(result) and len(result) == 68

    @staticmethod
    def is_valid_receipt_json(data):
        return data and isinstance(data, dict) and len(data) > 0 and \
            'status' in data and data['status'] == 0 and \
            'receipt' in data and isinstance(data['receipt'], dict) and len(data['receipt']) > 0 and \
            'bundle_id' in data['receipt'] and data['receipt']['bundle_id'] == IAP.BUNDLE_ID and \
            'in_app' in data['receipt'] and isinstance(data['receipt']['in_app'], list) and len(data['receipt']['in_app']) > 0

    @staticmethod
    def is_valid_receipt_in_app_json(data):
        return data and isinstance(data, dict) and \
            'product_id' in data and data['product_id'] and len(data['product_id']) > 0 and \
            'purchase_date' in data and data['purchase_date'] and len(data['purchase_date']) > 0

    @staticmethod
    def is_valid_product_id(product_id):
        return product_id == IAP.PRODUCT_ID_VIP_ONE or \
            product_id == IAP.PRODUCT_ID_VIP_THREE or \
            product_id == IAP.PRODUCT_ID_VIP_SIX or \
            product_id == IAP.PRODUCT_ID_VIP_TWELVE

    @staticmethod
    def product_from_receipt(receipt):
        data = IAP.get_iap_json_from_receipt(receipt)
        if data and isinstance(data, dict) and len(data) > 0 and 'status' in data and data['status'] == 21007:
            data = IAP.get_iap_json_from_receipt(receipt, False)

        if IAP.is_valid_receipt_json(data):
            product = {}
            for purchased in data['receipt']['in_app']:
                if IAP.is_valid_receipt_in_app_json(purchased) and IAP.is_valid_product_id(purchased['product_id']):
                    if len(product) > 0:
                        purchase_date = Utility.str_to_date(purchased['purchase_date'], IAP.PURCHASE_DATE_FORMAT)
                        if purchase_date > product['purchase_date']:
                            product['bundle_id'] = data['receipt']['bundle_id']
                            product['product_id'] = purchased['product_id']
                            product['purchase_date'] = Utility.str_to_date(purchased['purchase_date'], IAP.PURCHASE_DATE_FORMAT)
                    else:
                        product['bundle_id'] = data['receipt']['bundle_id']
                        product['product_id'] = purchased['product_id']
                        product['purchase_date'] = Utility.str_to_date(purchased['purchase_date'], IAP.PURCHASE_DATE_FORMAT)
            return product if len(product) > 0 else None
        return None

    @staticmethod
    def get_iap_json_from_receipt(receipt, is_product=True):
        receipt_str = '{0}'.format(receipt) if receipt else ''
        if len(receipt_str) > 1000:
            url = IAP.RECEIPT_VERIFY_URL if is_product else IAP.RECEIPT_VERIFY_URL_SANDBOX
            data = '{{"receipt-data": "{0}"}}'.format(receipt_str)
            headers = {'Content-Type': 'application/json', 'Content-Length': '{0}'.format(len(data))}
            handler = urllib2.HTTPHandler()
            opener = urllib2.build_opener(handler)
            request = urllib2.Request(url, data, headers)
            request.get_method = lambda: 'POST'

            try:
                connection = opener.open(request)
            except urllib2.HTTPError, e:
                connection = e

            if connection.code == 200:
                response = connection.read()
                try:
                    return json.loads(response)
                except:
                    pass
        return None

class Advertise(object):
    PROVIDER_ADMOB = 'admob'
    PROVIDER_BAIDU = 'baidu'

    _click_rate = {
        'admob': 0.02,
        'baidu': 0.02
    }

    _commands = {
        'log_presented': "echo 'user_id:{0}|ip:{1}|date:{2}' >> /etc/feiti/console/ad/{3}/presented",
        'log_clicked': "echo 'user_id:{0}|ip:{1}|date:{2}' >> /etc/feiti/console/ad/{3}/clicked",
        'count_presented': "cat /etc/feiti/console/ad/{0}/presented | grep -c '|date:{1}'",
        'count_clicked': "cat /etc/feiti/console/ad/{0}/clicked | grep -c '|date:{1}'"
    }

    _black_list_ip = ['180.172.221.126', '210.13.83.19']

    @staticmethod
    def is_valid_provider(provider):
        return provider == Advertise.PROVIDER_ADMOB or provider == Advertise.PROVIDER_BAIDU

    @staticmethod
    def log_presented(user_id, provider, ip):
        if Advertise.is_valid_provider(provider) and not (ip in Advertise._black_list_ip):
            now = Utility.date_to_str(Utility.get_utc_date(), Utility.DATE_FORMAT_FOR_ID_USAGE)
            return LinuxCommand.execute_query(Advertise._commands['log_presented'].format(user_id, ip, now, provider))
        return False

    @staticmethod
    def log_clicked(user_id, provider, ip):
        if Advertise.is_valid_provider(provider):
            now = Utility.date_to_str(Utility.get_utc_date(), Utility.DATE_FORMAT_FOR_ID_USAGE)
            return LinuxCommand.execute_query(Advertise._commands['log_clicked'].format(user_id, ip, now, provider))
        return False

    @staticmethod
    def count_presented(provider):
        if Advertise.is_valid_provider(provider):
            now = Utility.date_to_str(Utility.get_utc_date(), Utility.DATE_FORMAT_FOR_ID_USAGE_ONLY_DATE)
            result = LinuxCommand.execute_read(Advertise._commands['count_presented'].format(provider, now))
            if Utility.is_solid_str(result) and result.isdigit():
                result = int(result)
                if result > -1:
                    return result
        return None

    @staticmethod
    def count_clicked(provider):
        if Advertise.is_valid_provider(provider):
            now = Utility.date_to_str(Utility.get_utc_date(), Utility.DATE_FORMAT_FOR_ID_USAGE_ONLY_DATE)
            result = LinuxCommand.execute_read(Advertise._commands['count_clicked'].format(provider, now))
            if Utility.is_solid_str(result) and result.isdigit():
                result = int(result)
                if result > -1:
                    return result
        return None

    @staticmethod
    def ad_present_click_rate(provider):
        if Advertise.is_valid_provider(provider):
            presented_count = Advertise.count_presented(provider)
            if presented_count and presented_count > 0:
                click_count = Advertise.count_presented(provider)
                if click_count:
                    return click_count * 1.0 / presented_count * 1.0
        return None

    @staticmethod
    def is_ad_presentable_clickable(provider):
        rate = Advertise.ad_present_click_rate(provider)
        if rate:
            if rate < Advertise._click_rate[provider]:
                return True, True
            else:
                return True, False
        return True, False

class FeiTiAPIHandler(BaseHTTPRequestHandler):
    HEADER_TEXT = 'text/plain'
    HEADER_HTML = 'text/html'
    HEADER_JPG = 'image/jpeg'
    HEADER_JSON = 'application/json'
    HEADER_FILE = 'application/octet-stream'

    ERROR_CODE_COMMON_INVALID_PARAMS = 1000  # Invalid parameters
    ERROR_CODE_COMMON_INVALID_JSON_RESPONSE = 1001  # Invalid JSON response
    ERROR_CODE_COMMON_INVALID_TOKEN = 1002  # Invalid Token
    ERROR_CODE_COMMON_TOKEN_TIMEOUT = 1003  # Token timeout
    ERROR_CODE_USER_SIGN_UP_FAILURE = 1500  # Fail to sign up
    ERROR_CODE_USER_SIGN_IN_FAILURE = 1501  # Fail to sign in
    ERROR_CODE_USER_UPDATE_PASSWORD_FAILURE = 1502  # Fail to update password
    ERROR_CODE_USER_FREE_REFRESH_FAILURE = 1503  # Fail to refresh free usage
    ERROR_CODE_USER_PURCHASE_FAILURE = 1504  # Fail to purchase
    ERROR_CODE_USER_POINTS_TO_VIP_FAILURE = 1505    # Fail to points to vip
    ERROR_CODE_USER_RESET_PASSWORD_FAILURE = 1506      # Fail to reset password
    ERROR_CODE_AD_LOG_PRESENT_FAILURE = 2000  # Fail to log ad present
    ERROR_CODE_AD_LOG_CLICK_FAILURE = 2001  # Fail to log ad click

    COMMAND_SYS_USER_VPN_AUTH = 'v2_sys_vpn_auth'
    COMMAND_IOS_SIGN_UP = 'v2_ios_sign_up'
    COMMAND_IOS_SIGN_IN = 'v2_ios_sign_in'
    COMMAND_IOS_AD_PRESENTED = 'v2_ios_ad_presented'
    COMMAND_IOS_AD_CLICKED = 'v2_ios_ad_clicked'
    COMMAND_IOS_USER_RESET_PASSWORD = 'v2_ios_user_reset_password'
    COMMAND_IOS_USER_UPDATE_PASSWORD = 'v2_ios_user_update_password'
    COMMAND_IOS_USER_FREE_REFRESH = 'v2_ios_user_free_refresh'
    COMMAND_IOS_USER_PURCHASE = 'v2_ios_user_purchase'
    COMMAND_IOS_USER_POINTS_EXCHANGE = 'v2_ios_user_points_exchange'
    COMMAND_MAC_SIGN_UP = 'v2_mac_sign_up'
    COMMAND_MAC_SIGN_IN = 'v2_mac_sign_in'

    TOKEN_EXPIRE_DURATION = 3 * 3600

    SYS_ALLOWED_IPS = ['180.172.221.126',  # local
                       '45.76.215.242',   # jp 1
                       '45.77.14.235']   # jp 2 vip

    @property
    def client_ip(self):
        ip = self.client_address[0] if len(self.client_address) == 2 else None
        ip = ip if (ip and len(ip) > 0) else None
        return ip

    def _set_headers(self, http_status=200, content_type=HEADER_JSON, content=None, filename=None):
        self.send_response(http_status)
        self.send_header('Content-Type', content_type)
        if content:
            self.send_header('Content-Length', len(content))
        if content_type == FeiTiAPIHandler.HEADER_FILE and filename and len(filename) > 0:
            self.send_header('Accept-Ranges', 'bytes')
            self.send_header('Content-Disposition', 'attachment;filename="{0}"'.format(filename))
        self.end_headers()

    def _get_post_command_and_params(self):
        command = None
        params = {}
        content_type = None
        content_length = -1
        for key in self.headers.keys():
            if key in ['Content-Type', 'content-type', 'Content-type']:
                content_type = self.headers[key]
            elif key in ['Content-Length', 'content-length', 'Content-length'] and '{0}'.format(self.headers[key]). \
                    isdigit():
                content_length = int(self.headers[key])

            if content_type and content_length > 0:
                break

        if content_type and content_type == FeiTiAPIHandler.HEADER_JSON and content_length > 0:
            content = self.rfile.read(content_length)
            json_content = None
            try:
                json_content = json.loads(content)
            except:
                pass

            if json_content and isinstance(json_content, dict) and \
                            'command' in json_content and json_content['command'] and len(json_content['command']) > 0:
                for key in json_content.keys():
                    if key == 'command':
                        command = json_content['command']
                    else:
                        params[key] = json_content[key]
        return command, params

    def _verify_request_params(self, params, names=[], error_handler=True):
        is_valid = True
        for name in names:
            is_valid = is_valid and name in params and params[name]
            if is_valid:
                is_valid = len(params[name]) > 0 if isinstance(params[name], str) else True
        if is_valid:
            return True

        if error_handler:
            self._error_handler(FeiTiAPIHandler.ERROR_CODE_COMMON_INVALID_PARAMS)

    def _format_request_params(self, params):
        output = {}
        if isinstance(params, dict):
            for key in params.keys():
                if isinstance(params[key], unicode):
                    output[key] = Utility.format_unicode_str('{0}', params[key])
                else:
                    output[key] = params[key]
        return output

    def _json_response_handler(self, content):
        if isinstance(content, dict):
            try:
                wrapped_content = {'status': 0, 'data': content}
                response = json.dumps(wrapped_content, ensure_ascii=False)
                if response and len(response) > 0:
                    self._set_headers(content=response)
                    self.wfile.write(response)
                    return
            except:
                pass
        self._error_handler(FeiTiAPIHandler.ERROR_CODE_COMMON_INVALID_JSON_RESPONSE)

    def _text_response_handler(self, content):
        if Utility.is_solid_str(content):
            try:
                self._set_headers(content=content)
                self.wfile.write(content)
            except:
                pass

    def _wrap_user_json(self, user):
        if User.is_valid_user(user):
            return {'account': user['email'] if User.is_email_verified_user(user) else user['account'],
                    'kind': user['kind'],
                    'expire': Utility.date_to_str(user['expire'], Utility.DATE_FORMAT_STANDARD),
                    'points': user['points'],
                    'hash': user['hash']}
        return None

    def _error_handler(self, code):
        content = {'status': code, 'data': None}
        response = json.dumps(content, ensure_ascii=False)
        if response and len(response) > 0:
            self._set_headers(content=response)
            self.wfile.write(response)

    def _token_handler(self, token, check_expire=True):
        user_id = Token.token_to_user_id(token, check_expire)
        if user_id:
            if user_id == -1:
                self._error_handler(FeiTiAPIHandler.ERROR_CODE_COMMON_TOKEN_TIMEOUT)
            else:
                return user_id
        else:
            self._error_handler(FeiTiAPIHandler.ERROR_CODE_COMMON_INVALID_TOKEN)

    def _sign_up_ios_handler(self, ip, uuid, ifna, duid):
        user = User.get_user_by_md5('ifna', ifna)
        password = User.new_password()
        if not user:
            user = User.get_user_by_md5('uuid', uuid)
            if not user:
                user = User.get_user_by_md5('duid', Utility.format_unicode_str('{0}_{1}', ip, duid))
                if not user:
                    user = User.new_guest_user(ip, {'uuid': uuid, 'ifna': ifna, 'duid': duid})

        if user:
            user['password'] = Utility.to_md5(password)
            user['hash'] = Utility.to_md5('{0}{1}'.format(user['user_id'], user['password']))
            if User.save_user(user):
                response = {'account': user['account'], 'password': password}
                self._json_response_handler(response)
                return

        self._error_handler(FeiTiAPIHandler.ERROR_CODE_USER_SIGN_UP_FAILURE)

    def _sign_up_mac_handler(self, ip, serial):
        user = User.get_user_by_md5('serial', serial)
        password = User.new_password()
        if not user:
            user = User.new_guest_user(ip, {'serial': serial})

        if user:
            user['password'] = Utility.to_md5(password)
            user['hash'] = Utility.to_md5('{0}{1}'.format(user['user_id'], user['password']))
            if User.save_user(user):
                response = {'account': user['account'], 'password': password}
                self._json_response_handler(response)
                return

        self._error_handler(FeiTiAPIHandler.ERROR_CODE_USER_SIGN_UP_FAILURE)

    def _sign_in_handler(self, account, password):
        user = User.get_user_by_email(account) if Utility.is_email_address(account) else User.get_user_by_account(account)
        if user and Utility.to_md5(password) == user['password']:
            user_token = Token.user_id_to_token(user['user_id'], FeiTiAPIHandler.TOKEN_EXPIRE_DURATION)
            configurations = Configurations.get_configurations()
            if configurations:
                response = configurations
                response['token'] = user_token
                response['user'] = self._wrap_user_json(user)
                ad = self._get_ad_info()
                if ad:
                    response['ad'] = ad
                    self._json_response_handler(response)
                    return
        self._error_handler(FeiTiAPIHandler.ERROR_CODE_USER_SIGN_IN_FAILURE)
        # self.send_error(FeiTiAPIHandler.ERROR_CODE_USER_SIGN_IN_FAILURE)

    def _get_ad_info(self):
        config = Configurations.get_configurations()
        ad = Advertise.is_ad_presentable_clickable(Advertise.PROVIDER_ADMOB)
        if config and isinstance(ad, tuple) and isinstance(ad[0], bool) and isinstance(ad[1], bool):
            ad_data = config['ad']
            ad_data['display_banner'] = True
            ad_data['is_banner_clickable'] = ad[1]
            ad_data['display_inter_ad'] = ad[1]
            return ad_data
        return None

    def _ad_presented_handler(self, user_id, provider, ip):
        if user_id and Advertise.is_valid_provider(provider) and \
           Advertise.log_presented(user_id, provider, ip):
            token = Token.user_id_to_token(user_id)
            ad = self._get_ad_info()
            if token and ad:
                response = {'token': token, 'ad': ad}
                self._json_response_handler(response)
                return
        self._error_handler(FeiTiAPIHandler.ERROR_CODE_AD_LOG_PRESENT_FAILURE)
        # self.send_error(FeiTiAPIHandler.ERROR_CODE_AD_LOG_PRESENT_FAILURE)

    def _ad_clicked_handler(self, user_id, provider, ip):
        if user_id and Advertise.is_valid_provider(provider) and \
           Advertise.log_clicked(user_id, provider, ip):
            token = Token.user_id_to_token(user_id)
            ad = self._get_ad_info()
            if token and ad:
                response = {'token': token, 'ad': ad}
                self._json_response_handler(response)
                return

        self._error_handler(FeiTiAPIHandler.ERROR_CODE_AD_LOG_CLICK_FAILURE)
        # self.send_error(FeiTiAPIHandler.ERROR_CODE_AD_LOG_CLICK_FAILURE)

    def _user_reset_password_handler(self, ip, uuid, ifna, duid):
        user = User.get_user_by_ifna(ifna)
        if not user:
            user = User.get_user_by_uuid(uuid)
            if not user:
                user = User.get_user_by_duid(Utility.format_unicode_str('{0}_{1}', ip, duid))

        if user:
            password = User.new_password()
            user['password'] = Utility.to_md5(password)
            user['hash'] = Utility.to_md5('{0}{1}'.format(user['user_id'], user['password']))
            if User.save_user(user):
                response = {'account': user['account'], 'password': password}
                self._json_response_handler(response)
                return
        self._error_handler(FeiTiAPIHandler.ERROR_CODE_USER_RESET_PASSWORD_FAILURE)

    def _user_update_password(self, user_id, password):
        user = User.get_user_by_user_id(user_id)
        if user:
            user = User.update_password(user, password)
            token = Token.user_id_to_token(user_id)
            if token and user and User.save_user(user):
                response = {'token': token,
                            'user': self._wrap_user_json(user)
                            }
                self._json_response_handler(response)
                return
        self._error_handler(FeiTiAPIHandler.ERROR_CODE_USER_UPDATE_PASSWORD_FAILURE)

    def _user_free_refresh_handler(self, user_id, ad_clicked=False):
        user = User.get_user_by_user_id(user_id)
        hour = Utility.get_random_int(1, 3)
        seconds = Utility.hour_to_second(hour)
        points = 100 if ad_clicked else Utility.get_random_int(1, 5)
        if user and User.is_user_expired(user):
            user = User.update_user_kind_expire(user, User.TYPE_FREE, seconds)
            Tracking.log_refresh(user, self.client_ip)
            if user:
                user = User.increase_user_points(user, points)
                if user and User.save_user(user):
                    token = Token.user_id_to_token(user_id)
                    if token and user:
                        response = {'token': token,
                                    'user': self._wrap_user_json(user),
                                    'hour': hour,
                                    'points': points
                                    }
                        self._json_response_handler(response)
                        return
        self._error_handler(FeiTiAPIHandler.ERROR_CODE_USER_FREE_REFRESH_FAILURE)

    def _user_points_to_vip_handler(self, user_id, points):
        user = User.get_user_by_user_id(user_id)
        if user and (User.is_user_expired(user) or user['kind'] == User.TYPE_FREE) and \
           isinstance(points, int) and points > 0 and isinstance(user['points'], int) and user['points'] >= points:
            user = User.decrease_user_points(user, points)
            days = 7 if points == 1000 else (15 if points == 2000 else (30 if points == 3000 else -1))
            if user and days > 0:
                user = User.update_user_kind_expire(user, User.TYPE_VIP, User.UPDATE_EXPIRE_SECONDS_DAY * days)
                token = Token.user_id_to_token(user_id)
                if user and token and User.save_user(user):
                    response = {'token': token,
                                'user': self._wrap_user_json(user)
                                }
                    self._json_response_handler(response)
                    return
        self._error_handler(FeiTiAPIHandler.ERROR_CODE_USER_POINTS_TO_VIP_FAILURE)

    def _user_purchase_handler(self, user_id, receipt):
        if user_id and Utility.is_solid_str(receipt) and len(receipt) > 100:
            user = User.get_user_by_user_id(user_id)
            if not IAP.is_receipt_exist(receipt):
                IAP.log_receipt(user_id, receipt)
            if user and not IAP.is_purchase_exist(receipt):
                product = IAP.product_from_receipt(receipt)
                if product and 'product_id' in product:
                    update_second = -1
                    if product['product_id'] == IAP.PRODUCT_ID_VIP_ONE:
                        update_second = User.UPDATE_EXPIRE_SECONDS_DAY * 30
                    elif product['product_id'] == IAP.PRODUCT_ID_VIP_THREE:
                        update_second = User.UPDATE_EXPIRE_SECONDS_DAY * 30 * 3
                    elif product['product_id'] == IAP.PRODUCT_ID_VIP_SIX:
                        update_second = User.UPDATE_EXPIRE_SECONDS_DAY * 30 * 6
                    elif product['product_id'] == IAP.PRODUCT_ID_VIP_TWELVE:
                        update_second = User.UPDATE_EXPIRE_SECONDS_DAY * 30 * 12
                    if update_second > 0:
                        user = User.update_user_kind_expire(user, User.TYPE_VIP, update_second)
                        if user and User.save_user(user):
                            IAP.log_purchase(user_id, receipt)
                            token = Token.user_id_to_token(user_id)
                            if token and user:
                                response = {'token': token,
                                            'user': self._wrap_user_json(user)
                                            }
                                self._json_response_handler(response)
                                return
        self._error_handler(FeiTiAPIHandler.ERROR_CODE_USER_FREE_REFRESH_FAILURE)
        # self.send_error(FeiTiAPIHandler.ERROR_CODE_USER_FREE_REFRESH_FAILURE)

    def _sys_vpn_auth(self, hash_value, kind):
        kind_value = Utility.to_int(kind)
        user = User.get_user_by_hash(hash_value)
        if kind_value and user and not User.is_user_expired(user) and user['kind'] >= kind_value:
            self._text_response_handler('1')

    def _is_sys_allowed_ip(self):
        return self.client_ip in FeiTiAPIHandler.SYS_ALLOWED_IPS

    def do_POST(self):
        command_and_params = self._get_post_command_and_params()
        command = command_and_params[0]
        params = self._format_request_params(command_and_params[1])
        client_ip = self.client_ip

        if command and client_ip:
            if command == FeiTiAPIHandler.COMMAND_IOS_SIGN_UP:
                if self._verify_request_params(params, ['uuid', 'duid', 'ifna']):
                    self._sign_up_ios_handler(client_ip, params['uuid'], params['ifna'], params['duid'])
            elif command == FeiTiAPIHandler.COMMAND_IOS_SIGN_IN:
                if self._verify_request_params(params, ['account', 'password']):
                    self._sign_in_handler(params['account'], params['password'])
            elif command == FeiTiAPIHandler.COMMAND_IOS_AD_PRESENTED:
                if self._verify_request_params(params, ['token', 'provider']):
                    user_id = self._token_handler(params['token'], False)
                    self._ad_presented_handler(user_id, params['provider'], self.client_ip)
            elif command == FeiTiAPIHandler.COMMAND_IOS_AD_CLICKED:
                if self._verify_request_params(params, ['token', 'provider']):
                    user_id = self._token_handler(params['token'], False)
                    self._ad_clicked_handler(user_id, params['provider'], self.client_ip)
            elif command == FeiTiAPIHandler.COMMAND_IOS_USER_RESET_PASSWORD:
                if self._verify_request_params(params, ['uuid', 'duid', 'ifna']):
                    self._user_reset_password_handler(client_ip, params['uuid'], params['ifna'], params['duid'])
            elif command == FeiTiAPIHandler.COMMAND_IOS_USER_UPDATE_PASSWORD:
                if self._verify_request_params(params, ['token', 'password']):
                    user_id = self._token_handler(params['token'])
                    self._user_update_password(user_id, params['password'])
            elif command == FeiTiAPIHandler.COMMAND_IOS_USER_FREE_REFRESH:
                if self._verify_request_params(params, ['token']):
                    user_id = self._token_handler(params['token'])
                    ad_clicked = 'ad' in params and isinstance(params['ad'], bool)
                    self._user_free_refresh_handler(user_id, ad_clicked)
            elif command == FeiTiAPIHandler.COMMAND_IOS_USER_PURCHASE:
                if self._verify_request_params(params, ['token', 'receipt']):
                    user_id = self._token_handler(params['token'])
                    self._user_purchase_handler(user_id, params['receipt'])
            elif command == FeiTiAPIHandler.COMMAND_IOS_USER_POINTS_EXCHANGE:
                if self._verify_request_params(params, ['token', 'points']):
                    user_id = self._token_handler(params['token'])
                    self._user_points_to_vip_handler(user_id, params['points'])
            elif command == FeiTiAPIHandler.COMMAND_SYS_USER_VPN_AUTH:
                if self._is_sys_allowed_ip() and self._verify_request_params(params, ['hash', 'kind'], False):
                    self._sys_vpn_auth(params['hash'], params['kind'])

class ThreadPoolMixIn(ThreadingMixIn):
    MAX_THREAD = 50
    THREAD_POOL = ThreadPool(MAX_THREAD)

    def process_request(self, request, client_address):
        ThreadPoolMixIn.THREAD_POOL.apply_async(self.process_request_thread, (request, client_address))

class ThreadPoolHTTPServer(ThreadPoolMixIn, TCPServer): pass

def run(server_class=ThreadPoolHTTPServer, handler_class=FeiTiAPIHandler, secure=True):
    ThreadPoolHTTPServer.allow_reuse_address = True
    port = 443 if secure else 80
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    if secure:
        httpd.socket = ssl.wrap_socket(httpd.socket, keyfile='./crt/server.key', certfile='./crt/server.crt', server_side=True, ca_certs='./crt/ca.crt')
    print 'Starting FeiTi API...'
    httpd.serve_forever()

if __name__ == "__main__":
    run(secure=True)
    # nohup python FeiTiAPI.py &