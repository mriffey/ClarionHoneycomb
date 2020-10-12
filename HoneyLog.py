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
honeyevent = libhoney.new_event()

with open(args.logfile) as json_file:
    logdata = json.load(json_file)
    print(logdata)
    for p in logdata['logs']:
        print('timestamp: ' + p['created_at'])
        print('log: ' + p['log'])
        print('')
        dt = pendulum.parse(p['created_at'])
        honeyevent.created_at = dt
        honeyevent.add_field('log', p['log'])
        honeyevent.send()

libhoney.close()
