from flask import Flask, request,render_template,Response,jsonify
import requests,json


app = Flask(__name__)


@app.route("/getAddressDetails",methods=["GET","POST"])
def getAddressDetails ():
    if request.method == 'GET':
        return render_template("loc.html")
    else:
        if request.method == 'POST':
            req = request.form['address']
            format = request.form['format']

            URL = "https://maps.googleapis.com/maps/api/geocode/"

            address = "?address="+req
            key = '&key=AIzaSyCOD3KvY2DDzEfel-NZ_LKIWXr86EF_EUw'
            qstr = URL + format + address + key
            resp = requests.get(
                qstr.replace("%", "%25").replace(" ", "%20").replace('"', "%22").replace('+', "%2B").replace(",", "%2C")
                .replace("<", "%3C").replace(">", "%3E").replace("#", "%23").replace("|", "7C"))

            if format == "json":

                loc = json.loads(resp.text)["results"][0]['geometry']["location"]
                add = json.loads(resp.text)["results"][0]['formatted_address']

                return jsonify({ "coordinates":loc, "address": add})

            elif format =="xml":

                co_ordinates = resp.text.split("<location>")[1].split("</location>")[0]
                address =  resp.text.split("<formatted_address>")[1].split("</formatted_address>")[0]

                xml_string = f"""<?xml version="1.0" encoding="UTF-8"?>
                <root>
                    <address>
                            {address}
                    </address>
                
                    <coordinates >
                           {co_ordinates}
                    </coordinates >              
                </root>
                   
                """


                return Response(xml_string, mimetype='text/xml')
        else:
            return jsonify({"message" : "Invalid return type"})






if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0',port=5002)