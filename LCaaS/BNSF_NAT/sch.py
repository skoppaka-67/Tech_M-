import schedule
# import oneclick
import time
# from oneclick import one_click

def task_sched():
    print("workiiiinnggggggg")
# schedule.every().day.at('17:57').do(oneclick.one_click())
schedule.every().day.at('18:27').do(task_sched)
# task_sched()

while True:
    schedule.run_pending()

    time.sleep(1)
    print('ran successfully')