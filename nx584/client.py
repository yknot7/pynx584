import json
import requests
import time


class Client(object):
    def __init__(self, url, api_key=None):
        self._url = url
        self._session = requests.Session()
        self._last_event_index = 0
        self._timeout = 10
        if api_key:
            self._session.headers.update({'X-Api-Key': api_key})

    def list_zones(self):
        r = self._session.get(self._url + '/zones', timeout=self._timeout)
        return r.json()['zones']

    def list_partitions(self):
        r = self._session.get(self._url + '/partitions', timeout=self._timeout)
        return r.json()['partitions']

    def arm(self, armtype='auto', partition=1):
        if armtype not in ['stay', 'exit', 'auto']:
            raise Exception('Invalid arm type')
        r = self._session.post(
            self._url + '/command',
            params={'cmd': 'arm',
                    'type': armtype,
                    'partition': partition},
            timeout=self._timeout)
        return r.status_code in (200, 204)

    def disarm(self, master_pin, partition=1):
        r = self._session.post(
            self._url + '/command',
            params={'cmd': 'disarm',
                    'master_pin': master_pin,
                    'partition': partition},
            timeout=self._timeout)
        return r.status_code in (200, 204)
        
    def siren(self, partition=1):
        r = self._session.post(
            self._url + '/command',
            params={'cmd': 'siren',
                    'partition': partition},
            timeout=self._timeout)
        return r.status_code in (200, 204)
        
    def set_bypass(self, zone, bypass):
        data = {'bypassed': bypass}
        r = self._session.put(self._url + '/zones/%i' % zone,
                              data=json.dumps(data),
                              headers={'Content-Type': 'application/json'},
                              timeout=self._timeout)
        return r.status_code == 200

    def get_user(self, master_pin, user_number):
        params = {}
        start = time.time()
        while True:
            if time.time() - start > 30:
                return None
            r = self._session.get(self._url + '/users/%i' % user_number,
                                  params=params,
                                  headers={'Master-Pin': master_pin},
                                  timeout=self._timeout)
            if r.status_code == 202:
                params['retry'] = 'yes'
                time.sleep(1)
                continue
            if r.status_code == 404:
                time.sleep(1)
                continue
            if r.status_code == 200:
                return r.json()
            print('Status code %i' % r.status_code)
            break

    def put_user(self, master_pin, user):
        cur_user = self.get_user(master_pin, user['number'])
        if not cur_user:
            return None
        r = self._session.put(self._url + '/users/%i' % user['number'],
                              headers={'Master-Pin': master_pin,
                                       'Content-Type': 'application/json'},
                              data=json.dumps(user),
                              timeout=self._timeout)
        if r.status_code == 200:
            return r.json()

    def get_events(self, index=None, timeout=None):
        if index is None:
            index = self._last_event_index
        if timeout is None:
            timeout = 60
        r = self._session.get(self._url + '/events',
                              params={'index': index,
                                      'timeout': timeout},
                              timeout=self._timeout)
        if r.status_code == 200:
            data = r.json()
            self._last_event_index = data['index']
            return data['events']

    def get_version(self):
        r = self._session.get(self._url + '/version', timeout=self._timeout)
        if r.status_code == 404:
            return '1.0'
        else:
            return r.json()['version']

    def get_info(self):
        r = self._session.get(self._url + '/version', timeout=self._timeout)
        if r.status_code == 404:
            return '1.0'
        else:
            return r.json()
