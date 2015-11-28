%{
#include <stdio.h>
#include <stdlib.h>	
#include <stdarg.h>
#include <string.h>
#include <iostream>
#include <climits>
#include <sstream>
#include <queue>
#include <vector>
#include <cctype>
#include <fstream>
#include <queue>
#include <thread>
extern "C" 
using namespace std;
void yyerror(char *);

struct EdgeNode   
{
	int vtxNO;		//指向下一个点
	int weight;
	EdgeNode *next;   
};

struct Gate_class					//here I declare the gate class
{
	int Gate_index;
	string Gate_name;
	string Gate_type;
	string Source_gate_name;
	int Fault_list[2] = {-1,-1};
	int Source_gate_index[20] = {-1,-1,-1,-1,-1,  -1,-1,-1,-1,-1,  -1,-1,-1,-1,-1,  -1,-1,-1,-1,-1};	
	bool visited;  
	int distance;  
	int path;  
	int indegree;   
	int Fan_out_number = 0;
	int Fan_in_number = 0;
	int level = -1;   //means the level of this gate, level = the max level of input + 1
	int level_count = 0;  //menas the number of inputs that have been counted, if level_count == Fan_in_number, then current number of level will be the final number of level
	bool inqueue = false; //check whether the object is now in gate_queue;
	EdgeNode *first[20];
}; 
int gate_counter = -1;
Gate_class gates[12000];
int tempupdater = 0;



struct Graph
{
	Gate_class *vertexList;//the size of this array is equal to vertexes, point to a address:start of vertex array    
	int vertexes;  //number of vertexes
	int edges;
};




%}

	%union {
	int val;
	char *name;
	}
	%token <name> NETNAME
	%token <val> FANINNET 
	%token <name> GATETYPE 
	%token <val> NETNO 
	%token <val> FANOUT
	%token <val> FANIN 
	%token <val> FAULT
	%token <name> FROMNAME



		%{
		void yyerror(char *);
		int yylex(void);
	%}

	%%
	netlist:
	| netlist line_item
	;
	line_item:   netname | faninnet | gatetype | netno | fanout | fanin | fault | fromname 
	 	;
	netname: NETNAME 					{gates[gate_counter].Gate_name = $1;}	
	faninnet: FANINNET 					{gates[gate_counter].Source_gate_index[tempupdater] = $1;
											tempupdater++;}
	gatetype: GATETYPE 					{gates[gate_counter].Gate_type = $1;}
	netno: NETNO 						{
											gate_counter++;
											gates[gate_counter].Gate_index = $1;
											tempupdater =0;
										}	
	fanout: FANOUT 						{gates[gate_counter].Fan_out_number = $1;}
	fanin: FANIN 						{gates[gate_counter].Fan_in_number = $1;}
	fault: FAULT 						{
										 if ($1 == 0){gates[gate_counter].Fault_list[0] = 1;}
										 if ($1 == 1){gates[gate_counter].Fault_list[1] = 1;}
										 }
	fromname : FROMNAME 				{gates[gate_counter].Source_gate_name = $1;}

	%%



	void yyerror(char *s)
	{
		fprintf(stdout, "%s\n", s);
	};

	void BuildGraph(Graph *&graph, int n)
	{
		if (graph == NULL)
		{
			graph = new Graph;			//graph is a pointer, pointed for the start of the memory
			//graph->vertexList = new Gate_class[7552];
			graph->vertexList = &gates[n];				//pointer:vertexList points to the address:start of set of nodes！！！！！！！！！！！！！！！！！！！！！！！！！！
			graph->vertexes = n;			// number of vertexes is n+1
			graph->edges = 0;
			cout << n;
			for (int i = 0; i <= n; i++)
			{
	            
				//stringstream ss;
				//ss << gates[i].Gate_name;
				//cout << gates[i].Gate_name << endl;
			    //graph->vertexList[i].Gate_name = gates[i].Gate_name;
			    graph->vertexList[i].Gate_name = gates[i].Gate_name;
				graph->vertexList[i].Gate_type = gates[i].Gate_type;
				graph->vertexList[i].Gate_index = gates[i].Gate_index;
				graph->vertexList[i].Fan_out_number = gates[i].Fan_out_number;
				graph->vertexList[i].Source_gate_name = gates[i].Source_gate_name;
				if(graph->vertexList[i].Gate_type == "from")
				{
					graph->vertexList[i].Fan_in_number = 1;
				}
				else
				{
					graph->vertexList[i].Fan_in_number = gates[i].Fan_in_number;
				}
				graph->vertexList[i].level = -1;
				graph->vertexList[i].level_count = 0;
				if(graph->vertexList[i].Gate_type == "from")
				{
				graph->vertexList[i].Fan_out_number = 1;
				graph->vertexList[i].Fan_in_number = 1;					
				}
				for(int j  = 0; j <=1; j++)
				{
					graph->vertexList[i].Fault_list[j] = gates[i].Fault_list[j];
				}
				for(int j = 0; j<=19; j++)
				{
					graph->vertexList[i].Source_gate_index[j] = gates[i].Source_gate_index[j];
				}
				graph->vertexList[i].path = -1;
				graph->vertexList[i].visited = false;
				for (int j = 0; j <= graph->vertexList[i].Fan_out_number - 1; j++)
				{
					graph->vertexList[i].first[j] = NULL; 
				}
				graph->vertexList[i].indegree = 0;
			}
		}
	}

	void PrintGraph(Graph *graph)
	{
		if (graph == NULL)
			return;
		//cout << " Gate NUmber is: " << gate_counter <<endl;
		//考虑到一点多边，所以我的输出风格需要变化
		for(int i = 0; i <= gate_counter; i++)
		{
			//cout << i << " " << graph->vertexList[i].Gate_name << " with " << graph->vertexList[i].Fan_out_number << endl;
			for(int j = 0; j<=graph->vertexList[i].Fan_out_number-1; j++)
			{
				EdgeNode *p = graph->vertexList[i].first[j];
				if (p != NULL)
				{
					cout << "    gatename = " << gates[i].Gate_name << " , to " << graph->vertexList[p->vtxNO].Gate_name << endl;
				}
			}

		}

		/*这部分是原文
		cout << "Vertex: " << graph->vertexes << "\n";
		cout << "Edge: " << graph->edges << "\n";
		for (int i = 0; i < graph->vertexes; i++)
		{
			cout << i + 1 << ": " << graph->vertexList[i].Gate_name << "->";
			EdgeNode *p = graph->vertexList[i].first;
			while (p != NULL)
			{
				cout << graph->vertexList[p->vtxNO].Gate_name << "->";
				p = p->next;
			}
			cout << "\n";
		}
		*/
		cout << "\n";
	}

	void AddEdge(Graph *graph, int v1, int v2)   //here, the v1 and v2 is the index of a gate, rather a gate_index!!! v1是source
	{
		if (graph == NULL) return;
		//if (v1 < 0 || v1 > graph->vertexes - 1) return;   //here it will consider whether the vertex is already existed, I need to change!!!
		//if (v2 < 0 || v2 > graph->vertexes - 1) return;
		//if (v1 == v2) return; //no loop is allowed  
		//貌似我们允许线的多次连接，所以我做了下面的修改
		//cout << "I am here for " << graph->vertexList[v1].Gate_name << " with Fan_out_number = " << graph->vertexList[v1].Fan_out_number << endl;
		for(int j = 0; j<=graph->vertexList[v1].Fan_out_number; j++)
		{
			//cout << "I am here for " << graph->vertexList[v1].Gate_name;
			if (graph->vertexList[v1].first[j] == NULL)
			{
				graph->vertexList[v1].first[j] = new EdgeNode;  
				graph->vertexList[v1].first[j]->next = NULL;
				graph->vertexList[v1].first[j]->vtxNO = v2;
				//graph->vertexList[v1].first->weight = weight;
				graph->edges++;
				graph->vertexList[v2].indegree++;
				//cout << "edge between: " << graph->vertexList[v1].Gate_name << " and " << graph->vertexList[v2].Gate_name << " Connected!" << endl; 
				return;
			}
		}		
		//貌似我们允许线的多次连接，所以我做了下面的修改

		/*
		//下面的注释是原文
		EdgeNode *p = graph->vertexList[v1].first;
		if (p == NULL)//is the first vertex's prvious is unknown
		{
			//can not be p = new EdgeNode;    
			graph->vertexList[v1].first = new EdgeNode;  
			graph->vertexList[v1].first->next = NULL;
			graph->vertexList[v1].first->vtxNO = v2;
			//graph->vertexList[v1].first->weight = weight;
			graph->edges++;
			graph->vertexList[v2].indegree++;
			return;
		}

		while (p->next != NULL)//move to the last node    
		{
			if (p->vtxNO == v2)//already exits. checking all nodes but the last one    
				return;

			p = p->next;
		}

		if (p->vtxNO == v2)//already exits. checking the first or the last node    
			return;

		EdgeNode *node = new EdgeNode;
		node->next = NULL;
		node->vtxNO = v2;
		//node->weight = weight;
		p->next = node;//last node's next is the new node    

		graph->edges++;
		graph->vertexList[v2].indegree++;
		*/
	}
	//这里是排序算法
		void Swap(Gate_class *array, int x, int y)
	{
	    Gate_class temp = array[x];
	    array[x] = array[y];
	    array[y] = temp;
	}
		void InsertSort(Gate_class *array, int size)
	{
	    for(int i = 1; i < size; i++)
	    {
	        for(int j = i; j > 0; j--)
	        {
	            if(array[j].Gate_index < array[j - 1].Gate_index)
	            {
	                Swap(array, j, j-1);
	            }
	        }
	    }
	}



/*

	void Add_PO(Graph *graph)  //遍历整个图，寻找哪里需要加上新的PO  -------->没有完成好
	{
		cout<<"here";
		Gate_class temp1;
		cout<<"here";
		int start_index = 20001;
		cout<<"here";
		for(int x = 0; x <= graph->vertexes-1; x++)
		{
			cout<<"here";
			temp1 = graph->vertexList[x];
			cout<<"This is: " << temp1.Gate_name << " " << "to " << graph->vertexList[temp1.first->vtxNO].Gate_name;
			if(temp1.first== NULL)   //意思就是，这个gate没有出边
			{
				//现在需要在原来的gates【】里面加上新的node，然后重新生成图，之后加上边
				//加上新的gates
				cout << " Here" <<endl;
				gates[gate_counter].Gate_index = start_index;
				gates[gate_counter].Gate_type = "PO";
				gates[gate_counter].Gate_name = "PO";
				gate_counter++;
				//重新生成图
			}

		}
//		BuildGraph(graph, gate_counter);
//		//加上边
//		AddEdge(graph, i, start_index);
	}
*/
	void Generate_result(Graph *graph, int size)
	{
		int temp1;
		string temp2;
		int  PO_index = 20001;
		ofstream out("out.txt");
		//cout << graph->vertexes <<endl;
		for(int i = 0; i<= graph->vertexes-1; i++)
		{
			if(graph->vertexList[i].Gate_type == "from")
			{
				continue;
			}
			else
			{
				int Output = 1; 
				//这里输出index
				out << graph->vertexList[i].Gate_index << " ";
				//这里输出种类

				if(graph->vertexList[i].Gate_type == "inpt")
				{
					out << "PI" << " ";
				}
			
				else if((graph->vertexList[i].Gate_type != "inpt")&&(graph->vertexList[i].Gate_type != "from"))
				{
					temp2 = graph->vertexList[i].Gate_type;
					//out << temp2 << " ";
					if(temp2 == "nand")		out << "NAND" << " ";
					if(temp2 == "nor")		out << "NOR" << " ";
					if(temp2 == "or")		out << "OR" << " ";
					if(temp2 == "xor")		out << "XOR" << " ";	
					if(temp2 == "and")		out << "AND" << " ";				
					if(temp2 == "buff")		out << "BUFF" << " ";
				}
				
				for(int j = graph->vertexList[i].Fan_out_number-1; j>=0; j--)
				{
						if(graph->vertexList[i].first[j] != NULL)
					{
						Output = 0;
						temp1 = graph->vertexList[i].first[j]->vtxNO;    //need change
						//cout << temp1 << endl;
					
						if(graph->vertexList[temp1].Gate_type == "from")
					{						
						temp1 = graph->vertexList[temp1].first[0]->vtxNO;
					}							
						out << graph->vertexList[temp1].Gate_index << " ";					
					//cout << graph->vertexList[temp1].Gate_index << " ";
					}	
					//cout << graph->vertexList[i].Gate_name	<< " with " << graph->vertexList[i].Fan_out_number <<  endl;		
				}

	
				if(Output == 1)
				{
					out << PO_index;
					PO_index++ ;
				}
			    out<<";"<<endl;
			}
		}

		for(int i = PO_index-1; i>= 20001; i--)
		{
			out << "PO" << " " << i << " ;" <<endl;
		}
	}

	void Fault_generation(Graph *graph, int size)
	{
		//算法： 1：按次序输出
		//		2：每个gate和input输出index 0 1 或者 2
		//		3: 每个fan输出 fanout-index fanin-index fault
		int fanin_index = -1;
		int fanout_index = -1;
		ofstream out("fault-list.txt");
		for(int i = 0; i <= size; i++)
		{
			if(graph->vertexList[i].Gate_type != "from")
			{
				//cout << graph->vertexList[i].Gate_type << endl;
				if(graph->vertexList[i].Fault_list[0] == 1)
				{
					out << graph->vertexList[i].Gate_index << " 0 0 " << endl;
				}
				if(graph->vertexList[i].Fault_list[1] == 1)
				{
					out << graph->vertexList[i].Gate_index << " 0 1 " << endl;
				}
				
			}

			else if(graph->vertexList[i].Gate_type == "from")
			{ 
				for(int k = 0; k <= size; k++)
				{
					for(int x = 0; x <= graph->vertexList[k].Fan_in_number-1; x++)
					{
						if(graph->vertexList[k].Source_gate_index[x] == graph->vertexList[i].Gate_index)
						{
							fanout_index = graph->vertexList[k].Gate_index;
							out << fanout_index << " " ;
							break;
						}
					}
				
				}
				for(int j = 0; j <= size; j++)
				{
					if(graph->vertexList[j].Gate_name == graph->vertexList[i].Source_gate_name)
					{
						fanin_index = graph->vertexList[j].Gate_index;
						out << fanin_index << " " ;
						break;
					}				
				}



				if(graph->vertexList[i].Fault_list[0] == 1)
				{
					out << "0\n";
				}
				if(graph->vertexList[i].Fault_list[1] == 1)
				{
					out << "1\n";				
				
				}
			}

		}
	}

	void init_levelization(Graph *graph, int size)
	{
		for(int i = 0; i <= size; i++)
		{
			if(graph->vertexList[i].Gate_type == "inpt")   //initialize the inputs
			{
				graph->vertexList[i].level = 0;		//initialize the number of level
				graph->vertexList[i].level_count = 0;		//make the number of level_count == Fan_in_number 
				for (int j = 0; j <= graph->vertexList[i].Fan_out_number - 1; j++)
				{
					EdgeNode *p = graph->vertexList[i].first[j];
					graph->vertexList[p->vtxNO].level = 1;
					graph->vertexList[p->vtxNO].level_count++;
					cout << graph->vertexList[i].Gate_name<< "is been initalized, level ==" << graph->vertexList[i].level << endl;
					cout << "and its next gate" << graph->vertexList[p->vtxNO].Gate_name<<" now has level_count = " << graph->vertexList[p->vtxNO].level_count << endl;
				}
			}

		}

	}

	void levelization(Graph *graph, int size)
	{
		
		Gate_class temp;
		vector<Gate_class> gate_vector;
		bool check;
		bool in_vector = false;
		int vector_index = 0;
		for(int i = 0; i <= size; i++)
		{
			if(graph->vertexList[i].Gate_type == "inpt") 
			{
				for (int j = 0; j <= graph->vertexList[i].Fan_out_number - 1; j++)
				{
					EdgeNode *p = graph->vertexList[i].first[j];
					gate_vector.insert(gate_vector.begin(),graph->vertexList[p->vtxNO]);
					vector_index ++;					
				}
				
			}
		}
//used to check the result of initinalization
		for(int i = 0; i <= gate_vector.size()-1; i++)
		{
			cout << gate_vector.at(i).Gate_name << endl;
		}

		while(gate_vector.empty() == false)
		{
			temp = gate_vector.back();
			gate_vector.pop_back();
			cout << "pop " << temp.Gate_name << " " << endl;
			if(temp.level_count == temp.Fan_in_number) //表示这个gate已经被label
			{
				cout << temp.Gate_name << " is labeled " << endl;
				for(int j = 0; j <= temp.Fan_out_number - 1; j++) //这个gate的所有的fanout中
				{

					EdgeNode *p = temp.first[j];
					for (int k = 0; k <= gate_vector.size() - 1; k++)
					{

						if(gate_vector.at(k).Gate_name == graph->vertexList[p->vtxNO].Gate_name) //如果这个gate的下一个gate在gate——vector中
						{
							
							if(gate_vector.at(k).level - 1 <= temp.level)	//赋值给level
							{
								gate_vector.at(k).level = temp.level + 1;
							}
							gate_vector.at(k).level_count++;	//使下一个gate的level_counter++
							
							for (int l = 0; l<=gate_vector.size() - 1; l++)		//如果下一个gate不在vector里面
							{
								if(gate_vector.at(k).Gate_name == gate_vector.at(l).Gate_name)
								{
									check = false;   //下一个gate在vector里面
									break;
								}
								else
								{
									check = true;	//下一个gate不在vector里面
								}
							}
							if(check)
							{
								gate_vector.insert(gate_vector.begin(), gate_vector.at(k));	//那么久把下一个gate放进vector开始的地方
								cout << " push1 " << gate_vector.at(k).Gate_name << endl;	
								//cout << "here" << endl;							
							}
							
	
							
									
							for(int it = 0; it <= gate_vector.size() - 1; it++)
							{
								cout << gate_vector.at(it).Gate_name << " with " << gate_vector.at(it).level_count;
							}
							cout << endl;
							break;
						}	
							
						
					}
					in_vector = false;
					for (int k = 0; k <= gate_vector.size() - 1; k++)
					{

						
						if(gate_vector.at(k).Gate_name == graph->vertexList[p->vtxNO].Gate_name)
						{
							in_vector = true;
							break;
						}	
					}
					if(in_vector == false)
					{
						//cout << temp.Gate_name << "next gate is not in vector" << endl;
						graph->vertexList[p->vtxNO].level = temp.level + 1;
						graph->vertexList[p->vtxNO].level_count++;
						gate_vector.insert(gate_vector.begin(), graph->vertexList[p->vtxNO]);
						cout << "push2 " << graph->vertexList[p->vtxNO].Gate_name << endl;
						//cout << graph->vertexList[p->vtxNO].Gate_name << " has level count = " << graph->vertexList[p->vtxNO].level_count << " and level " << graph->vertexList[p->vtxNO].level << endl;
					}
				}
			}
			else
			{
				cout << "push " << temp.Gate_name << " " << endl;
				gate_vector.insert(gate_vector.begin(), temp);
			}
		}		

/*

		for(int i = 0; i <= size; i++)
		{

			cout << graph->vertexList[i].Gate_name <<" has number of fanin = " << graph->vertexList[i].Fan_in_number << endl;
			
		}
		while(gate_queue.empty() == false)
		{
			temp = gate_queue.front();
			gate_queue.pop();
			temp.inqueue = false;
			//cout << " pop out " << temp.Gate_name<<endl;
			//cout << temp.Gate_name << " " << temp.level_count <<"?"<< temp.Fan_in_number << endl;
			if(temp.level_count == temp.Fan_in_number)
			{
				//cout << temp.Gate_name << " is labeled " <<endl;
				cout << temp.Gate_name <<endl;
				for (int j = 0; j <= temp.Fan_out_number - 1; j++)
				{
					EdgeNode *p = temp.first[j];
					if(graph->vertexList[p->vtxNO].level -1 <= temp.level)
					{
						graph->vertexList[p->vtxNO].level = temp.level + 1;
					}
					graph->vertexList[p->vtxNO].level_count++; //此处，虽然下一个gate的level_count增加，但是并不能增加queue里面的元素的level_count的值，元素在不用的地方
					cout << " " << graph->vertexList[p->vtxNO].Gate_name << " has level: " << graph->vertexList[p->vtxNO].level << " and count: "<< graph->vertexList[p->vtxNO].level_count<<endl;
					if(graph->vertexList[p->vtxNO].level_count == graph->vertexList[p->vtxNO].Fan_in_number)
					{
						cout << graph->vertexList[p->vtxNO].Gate_name << " is ready" << endl;
					}
					//cout << "size = " << gate_queue.size() << " " << gate_queue.front().Gate_name << " and back:" << gate_queue.back().Gate_name<<endl;
					if(graph->vertexList[p->vtxNO].inqueue == false)
					{
						gate_queue.push(graph->vertexList[p->vtxNO]);
						graph->vertexList[p->vtxNO].inqueue = true;
					}
					
					//cout << " the next is: " << graph->vertexList[p->vtxNO].Gate_name<<endl;

				}

				
			}
			else if(temp.level_count << temp.Fan_in_number)
			{
				//out << "push back " << temp.Gate_name << endl;
				temp.inqueue = true;
				gate_queue.push(temp);

			}

		}

*/
//		for(int i = 0; i <= size; i++)
//		{
//			cout << graph->vertexList[i].Gate_name << " has level == " << graph->vertexList[i].level; 
//		}	
	

	}



	int main(void){

		yyparse();
/*
		for(int i = 0; i<=gate_counter; i++)
		{
			cout << gates[i].Gate_index << " " << gates[i].Gate_name << " " << gates[i].Gate_type << " ";
			if(gates[i].Gate_type == "from")
			{
				cout << gates[i].Source_gate_name << " " ;
					if(gates[i].Fault_list[0] == 1)
					{
						cout << ">SA0" << " ";
					}
					if(gates[i].Fault_list[1] == 1)
					{
						cout << ">SA1" << " ";
					}
					cout << endl;
			}

			else if(gates[i].Gate_type == "inpt")
			{
				cout << gates[i].Fan_out_number << " " << gates[i].Fan_in_number << " ";
				if(gates[i].Fault_list[0] == 1)
				{
					cout << ">SA0" << " ";
				}
				if(gates[i].Fault_list[1] == 1)
				{
					cout << ">SA1" << " ";
				}
				cout << endl;
			}
			else
			{
				cout << gates[i].Fan_out_number << " " << gates[i].Fan_in_number << " ";
				if(gates[i].Fault_list[0] == 1)
				{
					cout << ">SA0" << " ";
				}
				if(gates[i].Fault_list[1] == 1)
				{
					cout << ">SA1" << " ";
				}	
				cout << endl;
				for(int j = 0; j <= gates[i].Fan_in_number-1; j++)
				{
					cout << gates[i].Source_gate_index[j] << " ";
				}
				
				cout << endl;
			}
		}
*/
		cout <<"Data collect successfully!" <<endl;
		//cout << "this is the total number of gate: " << gate_counter<<endl;
		/*for(int j = 0; j<= gate_counter-1; j++)
		{
			cout<<gates[j].Gate_index << " " << gates[j].Gate_name << " " << gates[j].Gate_type << " " <<endl; 
		}*/
		for(int i = 0; i<=gate_counter; i++)
		{
			cout << i << endl;
			cout<<gates[i].Gate_name<<" ";
			cout<<gates[i].Gate_index<<" ";
			cout<<gates[i].Gate_type<<endl;
		}
		Graph *graph = NULL;
		int start_index = 20001;
		//InsertSort(gates, gate_counter);
		cout << " -------------------------------------- " <<endl;


		cout << "Data is cleaned up!" << endl;
		BuildGraph(graph, gate_counter+1);
		cout << "Graph is built!" << endl;
		for(int i = 0; i<=gate_counter; i++)
		{
			cout << i << endl;
			cout<<gates[i].Gate_name<<" ";
			cout<<gates[i].Gate_index<<" ";
			cout<<gates[i].Gate_type<<endl;
		}	
		cout << "Vertex: " << graph->vertexes << "\n";
		cout << "Edge: " << graph->edges << "\n";
		//PrintGraph(graph);
		//now I need to carefully arrange edges

	
		for(int i = 0; i <= gate_counter; i++)
		{
			if(gates[i].Gate_type == "from")
			{	//cout << "find a fan with index: " << graph->vertexList[i].Gate_index << " ";
				for(int j = 0; j <= gate_counter; j++)
				{
					if(gates[j].Gate_name == gates[i].Source_gate_name)
					{	//cout << "find its origin " << gates[j].Gate_index << endl;
						AddEdge(graph, j, i);
						//cout << "edge between: " << gates[j].Gate_name << " and " << gates[i].Gate_name << " Connected!" << endl; 
					}
				}

			}

			else if(gates[i].Gate_type != "inpt")  //现在找到了gate
			{
				cout << "the gate is: " << graph->vertexList[i].Gate_name << " with source index: " ;
				for (int k = 0; k <= gates[i].Fan_in_number-1 ; k++)
				{
					cout << graph->vertexList[i].Source_gate_index[k]<<endl;
					for(int j = 0; j <= gate_counter; j++)
					{
						if(gates[j].Gate_index == gates[i].Source_gate_index[k])
					{
						AddEdge(graph, j, i);
					}

					}
				}
				cout << endl;
			}
		}


		//cout <<"Edgeds are added" << endl;

		//cout<<"here";
		//Add_PO(graph);
		//cout << "PO is added" <<endl;
		//cout<<"Here is the gates name, index and type:"<<endl;
		for(int i = 0; i<=gate_counter; i++)
		{
			cout<<graph->vertexList[i].Gate_name<<" ";
			cout<<graph->vertexList[i].Gate_index<<" ";
			cout<<graph->vertexList[i].Gate_type<<endl;
		}
		cout << " -------------------------------------- " <<endl;
		cout << "gate_counter = " << gate_counter << endl;
		for(int i = 0; i<=gate_counter; i++)
		{
			cout << i << endl;
			cout<<gates[i].Gate_name<<" ";
			cout<<gates[i].Gate_index<<" ";
			cout<<gates[i].Gate_type<<endl;
		}		

		cout << "Vertex: " << graph->vertexes << "\n";
		cout << "Edge: " << graph->edges << "\n";
		cout << "Print Edge" << endl;
		PrintGraph(graph);


		//BFS(graph);
		Generate_result(graph, gate_counter);
		Fault_generation(graph, gate_counter);

		init_levelization(graph, gate_counter);
		levelization(graph, gate_counter);
		for(int i = 0; i <= gate_counter; i++)
		{
			cout << graph->vertexList[i].Gate_name << " has level = " << graph->vertexList[i].level << endl;
		}

		return 0;


	}