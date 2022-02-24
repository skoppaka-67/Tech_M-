from flask import Flask, request, jsonify, flash, session, redirect, url_for, render_template
from flask_httpauth import HTTPBasicAuth
import re, json,jwt,datetime
from urllib.parse import unquote
from functools import wraps
from pymongo import MongoClient
import pymongo

#client = MongoClient('13.233.230.164', 27017)
client = MongoClient('mongodb://uname:password@13.233.230.164:27017/')
db = client['MDB']

session_counter = 0

app = Flask(__name__)
auth = HTTPBasicAuth()
app.config['SECRET_KEY'] = "8aacf358ee03b9e906455587c9538669"

User_DATA = db.user.find({}, {"_id": 0})[0]

def token_required(f):
    @wraps(f)
    def decorated(*args,**kwargs):
        token = None
        if 'token' in session:
            token = session['token']
        if not  token:
            return render_template("login.html")
        try:
            data = jwt.decode(token,app.config['SECRET_KEY'])
            # current_user =  db.user.find({"username":data['username']}, {"_id": 0})[0]
            current_user = data['username']
        except:
            print("exception token",token)
            return  render_template("login.html")
        return f(current_user,*args,**kwargs)
    return decorated

@app.route('/add_data', methods=["GET", "POST"])
@token_required
def add_data(current_user):

    if request.method == 'GET' and len(session) > 0:

        if session['username'] == User_DATA['username']:
            return render_template('add_data.html')

    if request.method == 'POST' and len(session) > 0:
        if current_user != 'admin':
            return jsonify({'message':'cannot perform that function!'})

        if session['username'] == User_DATA['username']:
            temp_var = request.get_data()
            temp_var = temp_var.decode('utf-8')
            temp_list = temp_var.split("&")

            popular = float(temp_list[0].split("=")[-1])

            director = str(temp_list[1].split("=")[-1])

            genre = ("".join(str(temp_list[2].split("=")[-1])).replace('"', '')).split("%2")

            imdb_score = float(str(temp_list[3].split("=")[-1]))

            name = str(str(temp_list[4].split("=")[-1]).replace('"', ''))

            data_on = {
                "99popularity": popular,
                "director": director,
                "genre": genre,
                "imdb_score": imdb_score,
                "name": name
            }
            try:
                cursor = db.movies.find({"name": name})
                results = list(cursor)
                if len(results) == 0:
                    db.movies.insert_one(data_on)
                    return render_template('Ok.html')
                else:
                    return "Movie data already Exists   " + "<br> <a href = '/add_data'>" + "click here to add data</a>"
            except Exception as e:
                return "Something went wrong! " + str(e)

        else:
            return "Not a admin user Not allowed"
    else:
        return render_template("login.html")


@app.route("/delete", methods=["POST", "GET"])
@token_required
def movie_delete(current_user):
    if request.method == 'GET' and len(session) > 0:

        if session['username'] == User_DATA['username']:
            return render_template('del.html')

    if request.method == 'POST' and len(session) > 0:
        if current_user != 'admin':
            return jsonify({'message':'cannot perform that function!'})

        if session['username'] == User_DATA['username']:
            temp_var = request.get_data()
            temp_var = temp_var.decode('utf-8')
            temp_var = temp_var.split("=")[-1]
            cursor = db.movies.find({"name": temp_var})
            results = list(cursor)
            if len(results) != 0:
                myquery = {"name": temp_var}
                db.movies.delete_one(myquery)
            else:
                return "NO RECORD FOUND requested delete is not possible"

            return "Data about " + temp_var + " is deleted from database"
        return render_template("login.html")
    else:
        return render_template("login.html")


@app.route('/home',methods=['GET'])
def my_home():
    # print(request.authorization.username)

    datavalue = {}
    limit = int(request.args['limit'])
    offset = int(request.args['offset'])  # final record index
    starting_id = db.movies.find().sort('_id', pymongo.ASCENDING)
    last_id = starting_id[offset]['_id']  # final record _id

    datavalue["next_url"] = '/home' + '?limit=' + str(limit) + '&offset=' + str(offset + limit)
    datavalue["prev_url"] = '/home' + '?limit=' + str(limit) + '&offset=' + str(offset - limit)
    
    cursor = db.movies.find({'_id': {'$gt': last_id}}, {"_id": 0}).sort('_id', pymongo.ASCENDING).limit(limit)

    datavalue["data"] = [record for record in cursor]



    return jsonify(datavalue)

@app.route('/index')
def index():
    return render_template('index.html')



@app.route('/search_by_name', methods=['GET', "POST"])
def search_by_name():
    if request.method == 'GET':
        return render_template("search.html")
    if request.method == 'POST':
        print(request.method)
        temp_var = request.get_data()
        temp_var = temp_var.decode('utf-8')
        temp_var = temp_var.split("=")[-1]
        movie_name = temp_var
        datavalue = {}
        datavalue["data"] = []
        cursor = db.movies.find({"name": movie_name}, {"_id": 0})

        datavalue["data"] = [record for record in cursor]
        if datavalue["data"] != []:
            return jsonify(datavalue)
        else:
            return "Record Not Found"


@app.route('/search_by_genre', methods=['GET', "POST"])
def search_by_genre():
    if request.method == 'GET':
        return render_template("search_genre.html")
    if request.method == 'POST':
        print(request.method)
        temp_var = request.get_data()
        temp_var = temp_var.decode('utf-8')
        temp_var = temp_var.split("=")[-1]
        genre_name = temp_var

        datavalue = {}
        datavalue["data"] = []
        cursor = db.movies.find({"genre": re.compile(genre_name, re.IGNORECASE)}, {"_id": 0})

        datavalue["data"] = [record for record in cursor]
        if datavalue["data"] != []:
            return jsonify(datavalue)
        else:
            return "Record Not Found"


@app.route('/edit1', methods=[ "POST"])
@token_required
def edit1(current_user):

    if request.method == 'POST':
        if current_user != 'admin':
            return jsonify({'message':'cannot perform that function!'})
        if len(session) > 0 and session['username'] == User_DATA['username']:
            temp_var = request.get_data()
            temp_var = temp_var.decode('utf-8')
            temp_list = temp_var.split("&")

            popular = float(unquote(temp_list[0].split("=")[-1]))

            director = str(unquote(temp_list[1].split("=")[-1])).replace("+"," ")

            genre = ("".join(str(unquote(temp_list[2])).split("=")[-1]).strip()).replace('"', '').replace("'",'').replace("+"," ").replace("[","").replace("]","").split(",")

            imdb_score = float(str(unquote(temp_list[3]).split("=")[-1]))

            name = str(str(unquote(temp_list[4]).split("=")[-1]).replace('"', '')).replace("'",'').replace("+"," ")

            data_on = {
                "99popularity": popular,
                "director": director,
                "genre": genre,
                "imdb_score": imdb_score,
                "name": name
            }
            newvalues = {"$set": data_on}
            db.movies.update_one({"name":name}, newvalues)
            flash("Update success ","success")
            return redirect(url_for("edit"))
        else:
            return redirect(url_for('login'))




@app.route('/edit', methods=['GET', "POST"])
@token_required
def edit(current_user):
    # search_by_genre/?option="War"
    if request.method == 'GET':
        if len(session) > 0 and session['username'] == User_DATA['username']:

            return render_template("edit1.html")
        else: return redirect(url_for('login'))
    if request.method == 'POST':
        if current_user != 'admin':
            return jsonify({'message':'cannot perform that function!'})

        if len(session) > 0 and session['username'] == User_DATA['username']:
            temp_var = request.get_data()
            temp_var = temp_var.decode('utf-8')
            temp_var = temp_var.split("=")[-1]
            movie_name = temp_var

            datavalue = {}
            datavalue["data"] = []
            cursor = db.movies.find({"name": movie_name}, {"_id": 0})

            datavalue["data"] = [record for record in cursor]

            if datavalue["data"] != []:
                print(datavalue)
                datavalue = datavalue['data'][0]
                print(datavalue)
                return render_template("edit.html",popu=datavalue["99popularity"],dir=datavalue['director'],gen=datavalue['genre'],score=datavalue["imdb_score"],name=datavalue['name'])
            else:
                return "Record Not Found"
        else:
            return redirect(url_for('login'))


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'GET' and len(session) > 0:

        if session['username'] == User_DATA['username']:
            return redirect(url_for('my_home'))
    if request.method == 'POST':

        print(request.form,User_DATA)
        if request.form['username'] == User_DATA['username'] and request.form['password'] == User_DATA['password']:

            if len(session) > 0 and session['username'] == request.form['username']:
                flash("Already logged In ")

            session['username'] = request.form['username']
            session['password'] = request.form['password']
            token = jwt.encode({'username':'admin','exp':datetime.datetime.utcnow()+datetime.timedelta(minutes=5)},app.config['SECRET_KEY'])
            session['token'] = token.decode('UTF-8')
            print("sessiontoken",session["token"])

            return redirect(url_for('index'))
    return render_template("login.html")


@app.route('/logout')
def logout():
    # remove the username from the session if it is there
    print(session)
    session.clear()

    return redirect(url_for('login'))


if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=5001)
