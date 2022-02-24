import os,sys
from flask import Flask,jsonify,request
import subprocess
import flask
import datetime ,pytz
from pymongo import MongoClient
from termcolor import colored, cprint
import config
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
client = MongoClient(config.database['hostname'], config.database['port'])
# if client.drop_database(config.database['database_name']):
#     cprint("db dropped","magenta")

os.chdir("D:\\bnsf\\BNSF_NAT\\one_click")

# app=Flask(__name__)
#
#
#
# @app.route('/addData')
# def addData():
# f = open('errors.txt', 'a')
# f.seek(0)
# f.truncate()
try:
    f = open('D:\\bnsf\\BNSF_NAT\\one_click\\errors.txt', 'a')
    f.seek(0)
    f.truncate()
    dbname = request.args.get("dbname")
    print("dbnme is", dbname)
    import config
    config.data("BNSF_NAT_POC_1")
    import Natural_Services
    Natural_Services.data("BNSF_NAT_POC_1")
    path = r"D:\bnsf\BNSF_NAT\one_click\Natural_Services.bat"
    subprocess.Popen(path, shell=True)

    try:
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("started:Master_Inv at "+current_time ,"yellow")
        import Master_Inv
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("Ended:Master_Inv at "+current_time,"green")
    except Exception as e:
        cprint(e,"red")
        pass
    try:
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("started:Cyclomatic_Complexities at "+ current_time,"yellow")
        import Cyclomatic_Complexities
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("Ended:Cyclomatic_Complexities at "+current_time ,"green")
    except Exception as e:
        cprint(e,"red")
        pass

    try:
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("started:cross_reference at "+ current_time,"yellow")
        import X_ref
        X_ref.main()
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("Ended:cross_reference at "+current_time,"green")
    except Exception as e:
        cprint(e,"red")
        pass

    try:
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("started:CRUD at "+ current_time,"yellow")
        import CRUD
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("Ended:CRUD at "+ current_time,"green")
    except Exception as e:
        cprint(e,"red")
        pass
    try:
        os.chdir("D:\\bnsf\\BNSF_NAT\\one_click")
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("started:ProcessFlow at "+current_time,"yellow")
        import ProcessFlow
        ProcessFlow.main()
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("Ended:ProcessFlow at "+ current_time,"green")
    except Exception as e:
        cprint(e,"red")
        pass
    #
    # # import Process_flow_extcalls
    # #
    # # Process_flow_extcalls.main()
    #
    try:
        os.chdir("D:\\bnsf\\BNSF_NAT\\one_click")
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("started:BRE at "+ current_time,"yellow")
        import BRE_Natural
        BRE_Natural.main()
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("Ended:BRE at "+ current_time,"green")
    except Exception as e:
        cprint(e,"red")
        pass

    try:
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("started:BRE-2 at "+current_time,"yellow")
        import Universal_BRE_2
        Universal_BRE_2.main()
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("Ended:BRE-2 at "+current_time,"green")
    except Exception as e:
        cprint(e,"red")
        pass
    try:
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("started:Missing_Comp at "+current_time,"yellow")
        import Missing_Comp
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("Ended:Missing_Comp at "+current_time,"green")
    except Exception as e:
        cprint(e,"red")
        pass
    try:
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("started:orphan at "+current_time,"yellow")
        import orphan
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("Ended:orphan at "+current_time,"green")
    except Exception as e:
         cprint(e,"red")
         pass
    try:
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("started:commented at "+current_time,"yellow")
        import commented
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("Ended:commented at "+current_time,"green")
    except Exception as e:
         cprint(e,"red")
         pass
    try:
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("started:codebase at "+current_time,"yellow")
        import codebase
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("Ended:codebase at "+current_time ,"green")
    except Exception as e:
        cprint(e,"red")
        pass
    try:
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("started:Glossary at " +current_time ,"yellow")
        import Glossary
        Glossary.PerPorcessDB()
        Glossary.main()
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("Ended:Glossary at "+current_time,"green")
    except Exception as e:
        cprint(e,"red")
        pass
    #import FLowChart
except Exception as e:
    from datetime import datetime
    exc_type, exc_obj, exc_tb = sys.exc_info()
    fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
    print(exc_type, fname, exc_tb.tb_lineno)
    f.write(str(datetime.now()))
    f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
        exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
    f.close()
    pass
#     resp = flask.Response("working!!!")
#     resp.headers['Access-Control-Allow-Origin'] = '*'
#     return jsonify("Success")
#
#
# if __name__ == '__main__':
#     app.run(port=5009)


