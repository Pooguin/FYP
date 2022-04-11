/*********************************************
 * OPL 20.1.0.0 Model
 * Author: Samuel Chan
 * Creation Date: Feb 19, 2022 at 9:05:11 AM
 *********************************************/

//Locations
int clientNum = ...;
range Clients = 1..clientNum;
range Vertices = 0..clientNum+1;

//Nurses
int nurseNum = ...;
range Nurses = 1..nurseNum;

//Days
int dayNum = ...;
range Days = 1..dayNum;

//Demand & cost
int demand[Vertices] = ...;
int maxq_dif = ...;
int cost[Vertices][Vertices] = ...;

//Time Window
int start[Vertices][Days] = ...;
int end[Vertices][Days] = ...;
int E = ...;
int L = ...;


//Big-M
int M = ...;
 
//Decision Variables
dvar boolean x[Vertices][Vertices][Nurses][Days]; // if nurse n travel i -> j on Day t
dvar boolean y[Vertices][Nurses][Days]; // if Vertex i is visited by Nurse n on Day t
dvar int+ w[Vertices][Nurses][Days]; // Service start time of i by n on Day t

//Objective    
minimize 
	sum (i, j in Vertices, n in Nurses, t in Days)
	  	cost[i][j] * x[i][j][n][t];

subject to{
  //Each client visited once
  ctClientVisit:
  forall (i in Clients)
    sum (t in Days, n in Nurses) y[i][n][t] == 1;
    
  //All nurses at depot
  ctNurseDepot1:
  forall (n in Nurses, t in Days)
    y[0][n][t] == 1;
  
  ctNurseDepot2:
  forall (n in Nurses, t in Days)
    y[clientNum+1][n][t] == 1;
  
  //In == Out
  ctFlow1:
  forall (i in Clients, n in Nurses, t in Days)
    sum (j in Vertices) x[i][j][n][t] == y[i][n][t];
  
  ctFlow2:
  forall (i in Clients, n in Nurses, t in Days)
    sum (j in Vertices) x[j][i][n][t] == y[i][n][t];
    
  ctDepotFlow1:
  forall (n in Nurses, t in Days)
    sum (j in Vertices) x[0][j][n][t] == 1;
  
  ctDepotFlow2:
  forall (n in Nurses, t in Days)
    sum (i in Vertices) x[i][clientNum+1][n][t] == 1;
    
  ctDepotFlow3:
  forall (n in Nurses, t in Days)
    sum (i in Vertices) x[i][0][n][t] == 0;
    
  ctDepotFlow4:
  forall (n in Nurses, t in Days)
    sum (j in Vertices) x[clientNum+1][j][n][t] == 0;
    
  //Time Windows
  ctStartTime:
  forall (i, j in Vertices, n in Nurses, t in Days)
    w[i][n][t] + demand[i] + cost[i][j] - M*(1-x[i][j][n][t]) <= w[j][n][t];
  
  ctEndTime:
  forall (i in Vertices, n in Nurses, t in Days)
    w[i][n][t] + demand[i] - M*(1-y[i][n][t]) <= end[i][t];
  
  ctFinishTime:
  forall (n in Nurses, t in Days)
    w[clientNum+1][n][t] <= L;
  
  ctTimeBound1:
  forall (i in Vertices, n in Nurses, t in Days)
    start[i][t] <= w[i][n][t];
    
  ctTimeBound2:
  forall (i in Vertices, n in Nurses, t in Days)
    w[i][n][t] <= end[i][t];
    
  //Workload Balance
  ctBalance:
  forall (n , m in Nurses)
    (sum (t in Days, i in Vertices) demand[i]*(y[i][n][t]-y[i][m][t]))
    + (sum (t in Days, i, j in Vertices) cost[i][j]*(x[i][j][n][t]-x[i][j][m][t])) <= maxq_dif; 
  
}


//results
execute POSTPROCESS {
  //print route
  var i, j, n, t;
  for (t in Days){
  	for (n in Nurses){
  		for (i in Vertices){
  			if (y[i][n][t] == 1) {
  				write ("day: ", t, "; Nurse: ", n, "-> ", i, "; start time: ", w[i][n][t], "\n");
			}				
		}
		write("\n");	
	}
	write("\n");	
  }
  
  //working hours for each nurse
  /*for (n in Nurses){
    var whours = 0;
    for (t in Days){
      whours = whours + w[clientNum+1][n][t];
      write("day ", t, ": ", w[clientNum+1][n][t], " minutes\n");
    }
    write("Nurse ", n, ": ", whours, " minutes\n\n");
  }*/
  
  
  for (n in Nurses){
    var thours = 0;
    for (t in Days){
      var whours = 0;
      for (i in Vertices){
        whours = whours + demand[i]*y[i][n][t];
        thours = thours + demand[i]*y[i][n][t];
      }
      write("day ", t, ": ", whours, " minutes\n");
    }
    write("Nurse ", n, ": ", thours, " minutes\n\n");
  }
  
  //total travel cost
  var totalcost = 0;
  for (n in Nurses){
    var tcost = 0;
    for (i in Vertices){
      for (j in Vertices){
        for (t in Days){
          tcost = tcost + cost[i][j] * x[i][j][n][t];
          totalcost = totalcost + cost[i][j] * x[i][j][n][t];
        }
      }
    }
    write("Nurse ", n, " travel:", tcost, " minutes\n");
  }
  write("total travel cost: ", totalcost, " minutes\n");
}
