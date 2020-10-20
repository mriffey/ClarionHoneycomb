import libhoney
import argparse
import pendulum
import json


parser = argparse.ArgumentParser()
parser.add_argument('--apikey', type=str)
parser.add_argument('--dataset', type=str)
parser.add_argument('--logfile', type=str)


args = parser.parse_args()
libhoney.init(writekey=args.apikey, dataset=args.dataset, debug=False)

with open(args.logfile) as json_file:
#  with open('c:\\dl\\test2.json') as json_file:
    logdata = json.load(json_file)
    print(logdata)
    for p in logdata['metrics']:
        # print('timestamp: ' + p['created_at'])
        # print('log: ' + p['log'])
        # print('')
        # print(p)
        honeyevent = libhoney.new_event()
        dt = pendulum.parse(p['created_at'])
        p.pop('created_at', None)
        print(p)
        honeyevent.add(p)
        honeyevent.created_at = dt
        honeyevent.send()

libhoney.close()
