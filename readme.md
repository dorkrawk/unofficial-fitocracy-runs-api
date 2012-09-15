# Unofficial Fitocracy Runs API
### A RESTful Way To Get Data About Not Resting

There is currently no official Fitocracy API and I wanted a way to get at my running information (plus I wanted an excuse to learn how to use Ruby and Heroku), so I wrote this.  It could certainly be expanded to become a more complete unofficial API if someone were motivated enough to work through the rest of the parsing.

I'm sure that Fitocracy will come out with its own official API soon, but for now I hope this some useful, basic read-only access to some data.

## API Usage

This unofficial RESTful API returns a json result from Fitocracy about a user's running history.  The main usage URL is: `http://unofficial-fitocracy-runs-api.herokuapp.com/runs/USERNAME`

To limit the number of runs retured add another LIMIT parameter:
`http://unofficial-fitocracy-runs-api.herokuapp.com/runs/USERNAME/LIMIT`

This will provide a responce in the following format:

    {
      "username": "dorkrawk",
      "userid": "138850",
      "userpic": "https://s3.amazonaws.com/static.fitocracy.com/site_media/user_images/profile/138850/89880909f86e8c4d7e47bf8265731785.jpg",
      "runs": [
        {
          "datetime": "2012-08-13T20:50:36-05:00",
          "activity": "Running",
          "time": "0:27:28",
          "distance_i": "4",
          "units_i": "mi",
          "distance_m": "6.4",
          "units_m": "km",
          "points": "708",
          "note": "Felt like doing a faster run today... 6:52 miles, not bad."
        },
        {
          "datetime": "2012-08-12T13:50:47-05:00",
          "activity": "Running",
          "time": "1:07:20",
          "distance_i": "6.9",
          "units_i": "mi",
          "distance_m": "11.2",
          "units_m": "km",
          "points": "876",
          "note": "Ran w/ Eileen to Caesar Chavez Park, ran around the park a bit then came home.  A really nice little run. "
        }
        ]
    }
    
## Contributors
* [Dave Schwantes](https://github.com/dorkrawk "dorkrawk")
* [PeteMS](https://github.com/petems "petems")