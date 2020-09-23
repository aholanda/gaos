from random import randint
import time

class Proc:
        FLOOR = 1
        
        def __init__(self, pid, prio):
                self.pid = pid
                self.orig_prio = prio
                self.curr_prio = prio
                self.is_descending = True
                self.scheduled = 0

        def recalc_prio(self):                                
                #self.curr_prio = (self.curr_prio % self.orig_prio) + 2

                # it was scheduled, somewhat implicit, careful here
                self.scheduled += 1
                
        def Print(self):
                print("pid={}, curr_prio/orig_prio={}/{}, #schedules={}".
                      format(self.pid, self.curr_prio, self.orig_prio, self.scheduled))
                
def choose_proc(procs):
        sigma = 0
        for i in range(N):
                sigma += procs[i].curr_prio

        point = randint(1, sigma)

        sigma = 0
        for i in range(N):
                sigma += procs[i].curr_prio
                #print('i=', i, 'sum=', sigma, 'point=', point)

                if point <= sigma:
                        return i

N = 128
MAXPRIO = 256
procs = [None] * N
for i in range(N):
        procs[i] = Proc(i, randint(1,MAXPRIO))

RUNS = 10000
runs = 0
while True:
        runs += 1
        i = choose_proc(procs)
        procs[i].recalc_prio()
        if runs % 1000 == 0:
                print(runs)
        #procs[i].Print()
        time.sleep(.01)
        if runs == RUNS:
                break

fn = '/tmp/' + 'N' + str(N) + '-P' + str(MAXPRIO) + '-R' + str(RUNS) + '.csv'
f = open(fn, 'w')
for i in range(N):
        f.write(str(procs[i].orig_prio) + ',' + str(procs[i].scheduled) + '\n')
f.close()
print('* Wrote {}'.format(fn))
