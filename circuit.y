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
#include <bitset>
extern "C" 
using namespace std;
void yyerror(char *);
struct input_info
{
	int value;
	string Source_name;
};
struct EdgeNode   
{
	int vtxNO;		//指向下一个点
	int weight;
	EdgeNode *next;   
};

struct Fault_class
{
	string Gate_name;
	string Gate_index;
	string Gate_type;
	string Fault;
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
	unsigned int value = 0;
	vector<unsigned int> input_value;
	EdgeNode *first[20];
}; 
int gate_counter = -1;
Gate_class gates[12000];
vector<Fault_class> Fault_vector;
vector<int> test_pattern;
int tempupdater = 0;
vector<Gate_class> Output_vector;
vector<Gate_class> Fault_free_gate_container;
vector<Gate_class> Fault_gate_container; 


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
			//cout << n;
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
			cout << i << " " << graph->vertexList[i].Gate_name << " with fanout number" << graph->vertexList[i].Fan_out_number << endl;
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
		//cout << "\n";
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
					if(temp2 == "not")		out << "NOT" << " ";			
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

		//cout << "result is generated" <<endl;
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
				//cout << "fault is generated" <<endl;

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
//					cout << graph->vertexList[i].Gate_name<< "is been initalized, level ==" << graph->vertexList[i].level << endl;
//					cout << "and its next gate" << graph->vertexList[p->vtxNO].Gate_name<<" now has level_count = " << graph->vertexList[p->vtxNO].level_count << endl;
				}
			}

		}

	}

	void gate_vector_reader (vector<Gate_class> &gate_vector)
	{
		for (int i = 0; i<= gate_vector.size() - 1; i++)
		{
			cout << gate_vector.at(i).Gate_index << "  ";
		}

		cout << endl;
	}

	void levelization(Graph *graph, int size)
	{
		
		Gate_class temp;
		vector<Gate_class> gate_vector;
		bool check;
		bool in_vector = false;
		bool init_check = false;
		//int vector_index = 0;
		for(int i = 0; i <= size; i++)
		{
			if(graph->vertexList[i].Gate_type == "inpt") 
			{
				for (int j = 0; j <= graph->vertexList[i].Fan_out_number - 1; j++)
				{
					EdgeNode *p = graph->vertexList[i].first[j];
					if(gate_vector.size() == 0)
					{
						gate_vector.insert(gate_vector.begin(),graph->vertexList[p->vtxNO]);
						//cout << "push in the first element" << endl;
					}
					else
					{
						for(int k = 0; k<= gate_vector.size() - 1; k++)
						{
							if(graph->vertexList[p->vtxNO].Gate_name == gate_vector.at(k).Gate_name)
							{
								init_check = true;
								break;
							}
						}
						if(init_check == false)
						{
							gate_vector.insert(gate_vector.begin(),graph->vertexList[p->vtxNO]);
						}
						init_check = false;	
					}
								
				}
				
			}
		}
		//gate_vector_reader(gate_vector);

		//cout << "all inpt are inqueue" <<endl;
		while(gate_vector.empty() == false)
		{
			//cout << "-----------------------------------------------" <<endl;
			//gate_vector_reader(gate_vector);
			temp = gate_vector.back();
			gate_vector.pop_back();

			if(temp.level_count == temp.Fan_in_number) //表示这个gate已经被label
			{

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
								graph->vertexList[p->vtxNO].level = temp.level + 1;
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
								gate_vector.insert(gate_vector.begin(), gate_vector.at(k));	//那么就把下一个gate放进vector开始的地方
						
							}     
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
						graph->vertexList[p->vtxNO].level = temp.level + 1;
						graph->vertexList[p->vtxNO].level_count++;
						gate_vector.insert(gate_vector.begin(), graph->vertexList[p->vtxNO]);
					}
					//in_vector = false;  新加的，不知道是否正确，但是如果出错，先考虑这里
				}
			}
			else
			{
				gate_vector.insert(gate_vector.begin(), temp);
			}

		}		
	}

	int random_generator()
	{
		unsigned int ran_num;
		
		ran_num = rand()%4294967295 + 1;
	//	cout <<"num:" << ran_num << endl;
		return ran_num;
	} 

	void test_pattern_generator(vector<int> &vect, int Num_inpt)	//(test_pattern, NumofInput)
	{
		for(int i = 0;i<=Num_inpt - 1;i++)
		{
			unsigned int temp = random_generator();
	//		cout << "here" <<endl;
			vect.push_back(temp);
			//cout << " test pattern: " << temp <<endl;
		}

	}

	void process_fault_free(Graph *graph, int size, vector<int> &test_pattern)
	{
		//cout << "Fault free circuit is under processing....." << endl;
		int test_pattern_index = 0;
		int temp = 0;
		int max_level = -1;
		//initialize input
		cout << "Input Pattern:" <<endl;
		for(int i = 0; i<=size; i++)
		{
			if(graph->vertexList[i].Gate_type == "inpt")
			{
				std::bitset<32> binary (test_pattern.at(test_pattern_index));
				cout << "<" << graph->vertexList[i].Gate_index << ">";
				cout << "[" << binary <<"]," <<endl;
				graph->vertexList[i].value = test_pattern.at(test_pattern_index);
				for (int it = 0; it <= graph->vertexList[i].Fan_out_number - 1; it++)
				{
					EdgeNode *p = graph->vertexList[i].first[it];

					graph->vertexList[p->vtxNO].input_value.push_back(graph->vertexList[i].value);
					
					//cout << " INPT: " <<graph->vertexList[i].Gate_name << " has input value = " << test_pattern.at(test_pattern_index);
					//cout << "-----"<<graph->vertexList[p->vtxNO].Gate_name << " has input value" << graph->vertexList[p->vtxNO].input_value.at(0) <<endl;

//					cout << " and output: " << graph->vertexList[i].value <<endl;
					//cout <<"------------------------------------------------------------------------------------------------------------------------------------" << endl;

				}
				test_pattern_index++;
			}
		}
		//process

		for(int k = 0; k <= size; k++)
		{
			if(graph->vertexList[k].level > max_level)
			{
				max_level = graph->vertexList[k].level;
			}
		}
		//cout << "Max level is: " << max_level <<endl;
		for(int level = 1; level <= max_level; level++)
		{
			//cout << endl <<"Current level is: " << level <<endl;
			for(int j = 0; j<=size; j++)
			{
				
				if(graph->vertexList[j].level == level)
				{

					//if(level == 4) {cout<<" current gate is: " << graph->vertexList[j].Gate_name << endl;}
					
					if( graph->vertexList[j].Gate_type == "from")
					{
						
//						cout << " with input size " << graph->vertexList[j].input_value.size()<<endl;
					
						EdgeNode *p = graph->vertexList[j].first[0];
						graph->vertexList[j].value = graph->vertexList[j].input_value.at(0);
//						cout << "here" <<endl;
						graph->vertexList[p->vtxNO].input_value.push_back(graph->vertexList[j].value);

						//cout << " FAN: " <<graph->vertexList[j].Gate_name << " has input value = ";
						for(int test_for_input = 0; test_for_input <= graph->vertexList[j].input_value.size() - 1; test_for_input++)
						{
							//cout << graph->vertexList[j].input_value.at(test_for_input) << " ";
						}
						//cout << " and output: " << graph->vertexList[j].value <<endl;
						//------------------------------------------------------------------------------------------------------------------------------------


						//cout << "------- and it has next gate: " << graph->vertexList[p->vtxNO].Gate_name << " with input_value = :";
						for (int fan_index = 0; fan_index <= (graph->vertexList[p->vtxNO].input_value.size() - 1); fan_index++)
						{
							//cout << graph->vertexList[p->vtxNO].input_value.at(fan_index) << "   ";
						}
						//cout << endl;
					}
					else if(graph->vertexList[j].Gate_type == "and")
					{

						temp = graph->vertexList[j].input_value[0];
						for(int input_index = 1; input_index <= graph->vertexList[j].Fan_in_number - 1; input_index++)
						{
							temp = temp & graph->vertexList[j].input_value[input_index];
						}
						graph->vertexList[j].value = temp;
						for (int it = 0; it <= graph->vertexList[j].Fan_out_number - 1; it++)
						{
							EdgeNode *p = graph->vertexList[j].first[it];
							graph->vertexList[p->vtxNO].input_value.push_back(graph->vertexList[j].value);
						}


						//cout << " AND: " <<graph->vertexList[j].Gate_name << " has input value = ";
						for(int test_for_input = 0; test_for_input <= graph->vertexList[j].input_value.size() - 1; test_for_input++)
						{
							//cout << graph->vertexList[j].input_value.at(test_for_input) << " ";
						}
						//cout << " and output: " << graph->vertexList[j].value <<endl;
						//------------------------------------------------------------------------------------------------------------------------------------

					}

					else if(graph->vertexList[j].Gate_type == "or")
					{
						temp = graph->vertexList[j].input_value[0];
						for(int input_index = 1; input_index <= graph->vertexList[j].Fan_in_number - 1; input_index++)
						{
							temp = temp | graph->vertexList[j].input_value[input_index];
						}
						graph->vertexList[j].value = temp;
						for (int it = 0; it <= graph->vertexList[j].Fan_out_number - 1; it++)
						{
							EdgeNode *p = graph->vertexList[j].first[it];
							graph->vertexList[p->vtxNO].input_value.push_back(graph->vertexList[j].value);
						}


						//cout << " NOR: " <<graph->vertexList[j].Gate_name << " has input value = ";
						for(int test_for_input = 0; test_for_input <= graph->vertexList[j].input_value.size() - 1; test_for_input++)
						{
							//cout << graph->vertexList[j].input_value.at(test_for_input) << " ";
						}
						//cout << " and output: " << graph->vertexList[j].value <<endl;
						//------------------------------------------------------------------------------------------------------------------------------------

						
					}
					else if(graph->vertexList[j].Gate_type == "nand")
					{

						temp = graph->vertexList[j].input_value[0];
						for(int input_index = 1; input_index <= graph->vertexList[j].Fan_in_number - 1; input_index++)
						{
							temp = temp & graph->vertexList[j].input_value[input_index];
						}
						graph->vertexList[j].value = ~temp;
						for (int it = 0; it <= graph->vertexList[j].Fan_out_number - 1; it++)
						{
							EdgeNode *p = graph->vertexList[j].first[it];
							graph->vertexList[p->vtxNO].input_value.push_back(graph->vertexList[j].value);
						}						

						//cout << " NAND: " <<graph->vertexList[j].Gate_name << " has input value = ";
						for(int test_for_input = 0; test_for_input <= graph->vertexList[j].input_value.size() - 1; test_for_input++)
						{
							//cout << graph->vertexList[j].input_value.at(test_for_input) << " ";
						}
						//cout << " and output: " << graph->vertexList[j].value <<endl;
						//------------------------------------------------------------------------------------------------------------------------------------



					}
					else if(graph->vertexList[j].Gate_type == "not")
					{


						graph->vertexList[j].value = ~(graph->vertexList[j].input_value.at(0));	
						//cout << endl;
						//cout << " NOT: " <<graph->vertexList[j].Gate_name << " has input value = ";
						for(int test_for_input = 0; test_for_input <= graph->vertexList[j].input_value.size() - 1; test_for_input++)
						{
							//cout << graph->vertexList[j].input_value.at(test_for_input) << " ";
						}
						//cout << " and output: " << graph->vertexList[j].value <<endl;
						//cout << "------with fanout: " << graph->vertexList[j].Fan_out_number << " next gate:";
						for (int it = 0; it <= graph->vertexList[j].Fan_out_number - 1; it++)
						{
							EdgeNode *p = graph->vertexList[j].first[it];
							//cout << graph->vertexList[p->vtxNO].Gate_name << " ";
							graph->vertexList[p->vtxNO].input_value.push_back(graph->vertexList[j].value);
							//cout << graph->vertexList[j].value << "   ";
						}	
						//cout << endl;					
						//------------------------------------------------------------------------------------------------------------------------------------

//						cout << endl;						
					}
					else if(graph->vertexList[j].Gate_type == "nor")
					{

						temp = graph->vertexList[j].input_value[0];
						for(int input_index = 1; input_index <= graph->vertexList[j].Fan_in_number - 1; input_index++)
						{
							temp = temp | graph->vertexList[j].input_value[input_index];
						}
						graph->vertexList[j].value = ~temp;
						for (int it = 0; it <= graph->vertexList[j].Fan_out_number - 1; it++)
						{
							EdgeNode *p = graph->vertexList[j].first[it];
							graph->vertexList[p->vtxNO].input_value.push_back(graph->vertexList[j].value);
						}	

						//cout << " NOR: " <<graph->vertexList[j].Gate_name << " has input value = ";
						for(int test_for_input = 0; test_for_input <= graph->vertexList[j].input_value.size() - 1; test_for_input++)
						{
							//cout << graph->vertexList[j].input_value.at(test_for_input) << " ";
						}
						//cout << " and output: " << graph->vertexList[j].value <<endl;
						//------------------------------------------------------------------------------------------------------------------------------------

					}
					else if(graph->vertexList[j].Gate_type == "xor")
					{

						temp = graph->vertexList[j].input_value[0];
						for(int input_index = 1; input_index <= graph->vertexList[j].Fan_in_number - 1; input_index++)
						{
							temp = temp ^ graph->vertexList[j].input_value[input_index];
						}
						graph->vertexList[j].value = temp;
						for (int it = 0; it <= graph->vertexList[j].Fan_out_number - 1; it++)
						{
							EdgeNode *p = graph->vertexList[j].first[it];
							graph->vertexList[p->vtxNO].input_value.push_back(graph->vertexList[j].value);
						}

						//cout << " XOR: " <<graph->vertexList[j].Gate_name << " has input value = ";
						for(int test_for_input = 0; test_for_input <= graph->vertexList[j].input_value.size() - 1; test_for_input++)
						{
							//cout << graph->vertexList[j].input_value.at(test_for_input) << " ";
						}
						//cout << " and output: " << graph->vertexList[j].value <<endl;
						//------------------------------------------------------------------------------------------------------------------------------------


					}
					
				}

			}
		}
		//cout << "fault free circuit has been processed!" <<endl;
	}

	void input_checker (Graph *graph, int size)
	{
		for(int i = 0; i<= size; i++)
		{
//			for(int j = 0; j <= graph->vertexList[i].input_value.size() -1; j++)
//			{
//			cout << graph->vertexList[i].Gate_name << "has input value: " << graph->vertexList[i].input_value.at(j) << " " ;
//			}
//			cout << endl;
//			cout <<  graph->vertexList[i].Gate_name << " has input value size = " << graph->vertexList[i].input_value.size() << endl;
		}
	}

	void empty_graph_input(Graph *graph, int size)
	{
		for(int i = 0; i <= size; i++)
		{
			graph->vertexList[i].input_value.clear();
		}
	}

	void process_fault(Graph *graph, int size, vector<int> &test_pattern, Fault_class Fault_element)
	{
		//cout << "Faulty circuit is under processing..." <<endl;
//		cout << "Fault is: " << Fault_element.Gate_name << " " << Fault_element.Fault << " " <<endl;
		int test_pattern_index = 0;
		
		int temp = 0;
		int max_level = -1;
		//initialize input
		empty_graph_input(graph, size);
		//input_checker(graph, size);
		for(int i = 0; i<=size; i++)
		{

			if(graph->vertexList[i].Gate_type == "inpt")
			{
				if(graph->vertexList[i].Gate_name == Fault_element.Gate_name)
				{
					if(Fault_element.Fault == "SA0")
					{
						graph->vertexList[i].value = 0;
//						cout << "fault site: " << graph->vertexList[i].Gate_name << " has fault and value is: " << graph->vertexList[i].value <<endl;
					}
					else if(Fault_element.Fault == "SA1")
					{
						graph->vertexList[i].value = 4294967295;
//						cout << "fault site: " << graph->vertexList[i].Gate_name << " has fault and value is: " << graph->vertexList[i].value <<endl;

					}
				}
				else
				{
					graph->vertexList[i].value = test_pattern.at(test_pattern_index);
				}
				for (int it = 0; it <= graph->vertexList[i].Fan_out_number - 1; it++)
				{
					EdgeNode *p = graph->vertexList[i].first[it];
					graph->vertexList[p->vtxNO].input_value.push_back(graph->vertexList[i].value);
//					cout << graph->vertexList[p->vtxNO].Gate_name << " with source " << graph->vertexList[i].Gate_name << " has input "<< graph->vertexList[i].value<<endl;
				}
				test_pattern_index++;
			}			
		}

//		input_checker(graph, size);


		//process

		for(int k = 0; k <= size; k++)
		{
			if(graph->vertexList[k].level > max_level)
			{
				max_level = graph->vertexList[k].level;
			}
		}
//		cout << "Max level is: " << max_level <<endl;
		for(int level = 1; level <= max_level; level++)
		{
			for(int j = 0; j<=size; j++)
			{

				if((graph->vertexList[j].level == level)&&(graph->vertexList[j].Gate_name != Fault_element.Gate_name))
				{

/*					cout << graph->vertexList[j].Gate_name << " is under calculating..." << " with size: " << graph->vertexList[j].input_value.size() << endl << " with input: ";
					for(int i = 0; i <= graph->vertexList[j].input_value.size() - 1; i++)
					{
						cout << graph->vertexList[j].input_value.at(i) << " ";
					}
*/					if( graph->vertexList[j].Gate_type == "from")
					{
						

						EdgeNode *p = graph->vertexList[j].first[0];
						graph->vertexList[j].value = graph->vertexList[j].input_value.at(0);
						graph->vertexList[p->vtxNO].input_value.push_back(graph->vertexList[j].value);
//						cout <<  " with output =" << graph->vertexList[j].value << endl;
//						cout << "------- and it has next gate: " << graph->vertexList[p->vtxNO].Gate_name << " with input_value = :";
						for (int fan_index = 0; fan_index <= (graph->vertexList[p->vtxNO].input_value.size() - 1); fan_index++)
						{
							//cout << graph->vertexList[p->vtxNO].input_value.at(fan_index) << "   ";
						}
//						cout << endl;
					}
					else if(graph->vertexList[j].Gate_type == "or")
					{
						temp = graph->vertexList[j].input_value[0];
						for(int input_index = 1; input_index <= graph->vertexList[j].Fan_in_number - 1; input_index++)
						{
							temp = temp | graph->vertexList[j].input_value[input_index];
						}
						graph->vertexList[j].value = temp;
						for (int it = 0; it <= graph->vertexList[j].Fan_out_number - 1; it++)
						{
							EdgeNode *p = graph->vertexList[j].first[it];
							graph->vertexList[p->vtxNO].input_value.push_back(graph->vertexList[j].value);
						}


						//cout << " NOR: " <<graph->vertexList[j].Gate_name << " has input value = ";
						for(int test_for_input = 0; test_for_input <= graph->vertexList[j].input_value.size() - 1; test_for_input++)
						{
							//cout << graph->vertexList[j].input_value.at(test_for_input) << " ";
						}
						//cout << " and output: " << graph->vertexList[j].value <<endl;
						//------------------------------------------------------------------------------------------------------------------------------------

						
					}
					else if(graph->vertexList[j].Gate_type == "and")
					{
						temp = graph->vertexList[j].input_value[0];
						for(int input_index = 1; input_index <= graph->vertexList[j].Fan_in_number - 1; input_index++)
						{
							temp = temp & graph->vertexList[j].input_value[input_index];
						}
						graph->vertexList[j].value = temp;
						for (int it = 0; it <= graph->vertexList[j].Fan_out_number - 1; it++)
						{
							EdgeNode *p = graph->vertexList[j].first[it];
							graph->vertexList[p->vtxNO].input_value.push_back(graph->vertexList[j].value);
						}
					}
					else if(graph->vertexList[j].Gate_type == "nand")
					{
						temp = graph->vertexList[j].input_value[0];
						for(int input_index = 1; input_index <= graph->vertexList[j].Fan_in_number - 1; input_index++)
						{
							temp = temp & graph->vertexList[j].input_value[input_index];
						}
						graph->vertexList[j].value = ~temp;
//						cout <<  " with output =" << graph->vertexList[j].value << endl;

						for (int it = 0; it <= graph->vertexList[j].Fan_out_number - 1; it++)
						{
							EdgeNode *p = graph->vertexList[j].first[it];
							graph->vertexList[p->vtxNO].input_value.push_back(graph->vertexList[j].value);
						}
					}
					else if(graph->vertexList[j].Gate_type == "not")
					{


						graph->vertexList[j].value = ~(graph->vertexList[j].input_value.at(0));	
//						cout << endl;
//						cout << " NOT: " <<graph->vertexList[j].Gate_name << " has input value = ";
						for(int test_for_input = 0; test_for_input <= graph->vertexList[j].input_value.size() - 1; test_for_input++)
						{
//							cout << graph->vertexList[j].input_value.at(test_for_input) << " ";
						}
//						cout << " and output: " << graph->vertexList[j].value <<endl;
//						cout << "------with next gate:";
						for (int it = 0; it <= graph->vertexList[j].Fan_out_number - 1; it++)
						{
							EdgeNode *p = graph->vertexList[j].first[it];
//							cout << graph->vertexList[p->vtxNO].Gate_name << " ";
							graph->vertexList[p->vtxNO].input_value.push_back(graph->vertexList[j].value);
//							cout << graph->vertexList[p->vtxNO].input_value.at(it) << "   ";
						}	
//						cout << endl;					
						//------------------------------------------------------------------------------------------------------------------------------------

//						cout << endl;						
					}
					else if(graph->vertexList[j].Gate_type == "nor")
					{

						temp = graph->vertexList[j].input_value[0];
						for(int input_index = 1; input_index <= graph->vertexList[j].Fan_in_number - 1; input_index++)
						{
							temp = temp | graph->vertexList[j].input_value[input_index];
						}
						graph->vertexList[j].value = ~temp;
						for (int it = 0; it <= graph->vertexList[j].Fan_out_number - 1; it++)
						{
							EdgeNode *p = graph->vertexList[j].first[it];
							graph->vertexList[p->vtxNO].input_value.push_back(graph->vertexList[j].value);
						}	

//						cout << " NOR: " <<graph->vertexList[j].Gate_name << " has input value = ";
						for(int test_for_input = 0; test_for_input <= graph->vertexList[j].input_value.size() - 1; test_for_input++)
						{
//							cout << graph->vertexList[j].input_value.at(test_for_input) << " ";
						}
//						cout << " and output: " << graph->vertexList[j].value <<endl;
						//------------------------------------------------------------------------------------------------------------------------------------

					}
					else if(graph->vertexList[j].Gate_type == "xor")
					{

						temp = graph->vertexList[j].input_value[0];
						for(int input_index = 1; input_index <= graph->vertexList[j].Fan_in_number - 1; input_index++)
						{
							temp = temp ^ graph->vertexList[j].input_value[input_index];
						}
						graph->vertexList[j].value = temp;
						for (int it = 0; it <= graph->vertexList[j].Fan_out_number - 1; it++)
						{
							EdgeNode *p = graph->vertexList[j].first[it];
							graph->vertexList[p->vtxNO].input_value.push_back(graph->vertexList[j].value);
						}

//						cout << " XOR: " <<graph->vertexList[j].Gate_name << " has input value = ";
						for(int test_for_input = 0; test_for_input <= graph->vertexList[j].input_value.size() - 1; test_for_input++)
						{
//							cout << graph->vertexList[j].input_value.at(test_for_input) << " ";
						}
//						cout << " and output: " << graph->vertexList[j].value <<endl;
						//------------------------------------------------------------------------------------------------------------------------------------


					}
					
				}

				else if((graph->vertexList[j].level == level) && (graph->vertexList[j].Gate_name == Fault_element.Gate_name))
				{

					//cout << "fault is: " << graph->vertexList[j].Gate_name << " " << Fault_element.Fault << endl;
//					cout << graph->vertexList[j].Gate_name << " with level " << graph->vertexList[j].level << " and fault " << Fault_element.Fault << " is now injecting..." <<endl;	
					if(Fault_element.Fault == "SA0")
					{
//						cout << ".....SA0" <<endl;
						graph->vertexList[j].value = 0;

						for (int it = 0; it <= graph->vertexList[j].Fan_out_number - 1; it++)
						{
//							cout << " driven gate is being re-configurated..."<<endl;
							EdgeNode *p = graph->vertexList[j].first[it];
							graph->vertexList[p->vtxNO].input_value.push_back(0);
//							cout << " driven gate: " << graph->vertexList[p->vtxNO].Gate_name << " is CONFIGURATED, now it has input_value = ";

//							cout << endl;

							//cout << graph->vertexList[p->vtxNO].Gate_name << " has been initalized" << endl;
						}

					}
					if(Fault_element.Fault == "SA1")
					{
//						cout << ".....SA1" <<endl;
						graph->vertexList[j].value = 4294967295;
	
						for (int it = 0; it <= graph->vertexList[j].Fan_out_number - 1; it++)
						{
							EdgeNode *p = graph->vertexList[j].first[it];							
							graph->vertexList[p->vtxNO].input_value.push_back(4294967295);
//							cout << " driven gate: " << graph->vertexList[p->vtxNO].Gate_name << " is CONFIGURATED, now it has input_value = ";

//							cout << endl;

							//cout << graph->vertexList[p->vtxNO].Gate_name << " has been initalized" << endl;

						}

					}
				}
					/*the following line are used to process SA at output*/
				if((graph->vertexList[j].level == max_level) && (graph->vertexList[j].Gate_name == Fault_element.Gate_name))
				{
					if(Fault_element.Fault == "SA0")
					{

						graph->vertexList[j].value = 0;
				//		cout << graph->vertexList[j].Gate_name << " is output, with value: " << graph->vertexList[j].value <<endl;

					}
					else if(Fault_element.Fault == "SA1")
					{
				//		cout <<"here"<<endl;
						graph->vertexList[j].value = 4294967295;
				//		cout << graph->vertexList[j].Gate_name << " is output, with value: " << graph->vertexList[j].value <<endl;


					}
				}

			}
		}
			//cout << "Faulty circuit has been processed..." <<endl;

	}
	

	void result_generator(Graph *graph, int size)
	{
		bool is_output = true;
		for (int i = 0; i <= size; i++)
		{
			//cout << graph->vertexList[i].Gate_name << " has value " << graph->vertexList[i].value <<endl;
		}
		//cout << "result is generated" <<endl;
	}

	void fault_collector(Graph *graph, int size, vector<Fault_class> &Fault_vector)
	{
		Fault_class Fault_element;
		for(int i = 0; i<= size; i++)
		{
			//cout << graph->vertexList[i].Gate_name << " ";
			if(graph->vertexList[i].Fault_list[0] == 1)
			{
				//cout << "SA0 ";
				Fault_element.Gate_name = graph->vertexList[i].Gate_name;
				Fault_element.Gate_index = graph->vertexList[i].Gate_index;
				Fault_element.Gate_type = graph->vertexList[i].Gate_type;
				Fault_element.Fault = "SA0";
				Fault_vector.push_back(Fault_element);
			}
			if(graph->vertexList[i].Fault_list[1] == 1)
			{
				//cout << "SA1";
				Fault_element.Gate_name = graph->vertexList[i].Gate_name;
				Fault_element.Gate_index = graph->vertexList[i].Gate_index;
				Fault_element.Gate_type = graph->vertexList[i].Gate_type;
				Fault_element.Fault = "SA1";
				Fault_vector.push_back(Fault_element);
			}
			//cout << endl;
		}
	}

	void output_finder(Graph *graph, int size, vector<Gate_class> &Output_vector)  //return Output_vector with output gate as elements
	{
		for(int i = 0; i<=size; i++)
		{
			if(graph->vertexList[i].first[0] == NULL)
			{
				Output_vector.push_back(graph->vertexList[i]);
			}
		}
	}

	bool is_identical(vector<Gate_class> &Fault_free_gate_container, vector<Gate_class> &Fault_gate_container, vector<Gate_class> &Output_vector)
	{	
		bool check = true;
		int size = Output_vector.size();
		for(int i = 0; i <= size - 1; i++)
		{
			//cout << Fault_gate_container.at(i).Gate_name << "=" << Fault_gate_container.at(i).value<<" VS " << Fault_free_gate_container.at(i).Gate_name <<"=" << Fault_free_gate_container.at(i).value<<endl;
			if(Fault_gate_container.at(i).value != Fault_free_gate_container.at(i).value)
			{
				check = false;
				
			}
		}

		return check;

	}

	void Following_faults_are_detected_at (Graph *graph, int size, vector<Gate_class> &Fault_free_gate_container, vector<Gate_class> &Fault_gate_container, vector<Gate_class> &Output_vector, Fault_class &Fault_element, bool is_identical)
	{
		//cout <<"here"<<endl;
		if(is_identical == false)
		{

			for(int i = 0; i <= Output_vector.size() - 1; i++)
			{
				if(Fault_free_gate_container.at(i).value != Fault_gate_container.at(i).value)
				{
					cout << "<" << Output_vector.at(i).Gate_index << ">";
					for(int j = 0; j <= size; j++)
					{
						if(graph->vertexList[j].Gate_name == Fault_element.Gate_name)
						{
						cout << "<" << graph->vertexList[j].Gate_index << ">";	
						break;						
						}
					}
					if(Fault_element.Fault == "SA1")
					{
						cout << "SA<1>" <<endl;
					}
					else if(Fault_element.Fault == "SA0")
					{
						cout << "SA<0>" <<endl;
					}
					break;
				}
			}
		}
	}

	void level_checker(Graph *graph, int size)
	{
		int max_level = 0;
		for(int k = 0; k <= size; k++)
		{
			if(graph->vertexList[k].level > max_level)
			{
				max_level = graph->vertexList[k].level;
			}
		}
		for (int level = 0; level <= max_level; level++)
		{
			cout << " level " << level << ":" << endl;
			for(int gate_index = 0; gate_index <= size; gate_index++)
			{
				if(graph->vertexList[gate_index].level == level)
				{
					cout << graph->vertexList[gate_index].Gate_name << " ";
				}
			}
			cout << endl;
		}
	}
	int main(void){

		int Num_of_inpt = 0;

		yyparse();
		cout << endl;
		cout <<"Data collect successfully!" <<endl;
		//cout << "this is the total number of gate: " << gate_counter<<endl;
		/*for(int j = 0; j<= gate_counter-1; j++)
		{
			cout<<gates[j].Gate_index << " " << gates[j].Gate_name << " " << gates[j].Gate_type << " " <<endl; 
		}*/
		for(int i = 0; i<=gate_counter; i++)
		{
			//cout << i << endl;
			//cout<<gates[i].Gate_name<<" ";
			//cout<<gates[i].Gate_index<<" ";
			//cout<<gates[i].Gate_type<<endl;
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
			//cout << i << endl;
			//cout<<gates[i].Gate_name<<" ";
			//cout<<gates[i].Gate_index<<" ";
			//cout<<gates[i].Gate_type<<endl;
		}	
		//cout << "Vertex: " << graph->vertexes << "\n";
		//cout << "Edge: " << graph->edges << "\n";
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
				//cout << "the gate is: " << graph->vertexList[i].Gate_name << " with source index: " ;
				for (int k = 0; k <= gates[i].Fan_in_number-1 ; k++)
				{
					//cout << graph->vertexList[i].Source_gate_index[k]<<endl;
					for(int j = 0; j <= gate_counter; j++)
					{
						if(gates[j].Gate_index == gates[i].Source_gate_index[k])
					{
						AddEdge(graph, j, i);
					}

					}
				}
				//cout << endl;
			}
		}


		//cout <<"Edgeds are added" << endl;

		//cout<<"here";
		//Add_PO(graph);
		//cout << "PO is added" <<endl;
		//cout<<"Here is the gates name, index and type:"<<endl;
		for(int i = 0; i<=gate_counter; i++)
		{
			//cout<<graph->vertexList[i].Gate_name<<" ";
			//cout<<graph->vertexList[i].Gate_index<<" ";
			//cout<<graph->vertexList[i].Gate_type<<endl;
		}
		cout << " -------------------------------------- " <<endl;
		cout << "gate_counter = " << gate_counter << endl;
		for(int i = 0; i<=gate_counter; i++)
		{
			//cout << i << endl;
			//cout<<gates[i].Gate_name<<" ";
			//cout<<gates[i].Gate_index<<" ";
			//cout<<gates[i].Gate_type<<endl;
		}		

		//cout << "Vertex: " << graph->vertexes << "\n";
		//cout << "Edge: " << graph->edges << "\n";
		//cout << "Print Edge" << endl;
		//PrintGraph(graph);


		//BFS(graph);
		Generate_result(graph, gate_counter);
		Fault_generation(graph, gate_counter);

		init_levelization(graph, gate_counter);
		cout << "level is initialized!!!" <<endl;
		//level_checker(graph, gate_counter);
		cout << "start to levelize!!!" <<endl;
		levelization(graph, gate_counter);
		//level_checker(graph, gate_counter);
		for(int i = 0; i <= gate_counter; i++)
		{
			//cout << graph->vertexList[i].Gate_name << " has level = " << graph->vertexList[i].level << endl;
		}

		for(int i = 0; i<=gate_counter; i++)
		{
			if (graph->vertexList[i].Gate_type == "inpt")
			{
				Num_of_inpt++;
			}
		}
		
		test_pattern_generator(test_pattern, Num_of_inpt);
		/*
		for (int i = 0; i<=test_pattern.size() - 1; i++)
		{
			cout << test_pattern.at(i) <<endl;
		}
		*/
		
		process_fault_free(graph, gate_counter, test_pattern);   //process and all the node in graph now have output_value
		output_finder(graph, gate_counter, Output_vector);		//找到outputnode，然后将他们复制放进事先声明的Output_finder里面，此时output_Vector里面的value是fault free时候的值
		for(int i = 0; i<= Output_vector.size() - 1; i++)
		{
			Fault_free_gate_container.push_back(Output_vector.at(i));
			//cout << Output_vector.at(i).Gate_name << " when fault free is: " << Output_vector.at(i).value <<endl;
		}
		//result_generator(graph, gate_counter);
		Output_vector.clear(); //清空Output_vector，以便放入新的fault_gate的output_vector
		fault_collector(graph, gate_counter, Fault_vector);  //搜集所有的fault gate和他们的fault类型
		cout << "Following faults are detected at:" << endl;
		for(int i = 0; i <= Fault_vector.size() - 1; i++)
		{
			//cout <<"................................................................." <<endl;
			//cout << "Fault: " << Fault_vector[i].Gate_name << " " << Fault_vector[i].Fault << " is processing..." <<endl;
			process_fault(graph, gate_counter, test_pattern, Fault_vector[i]);
			//result_generator(graph, gate_counter);
			Output_vector.clear();
			output_finder(graph, gate_counter, Output_vector);
			for(int i = 0; i<= Output_vector.size() - 1; i++)
			{
				Fault_gate_container.push_back(Output_vector.at(i));
				//cout << Output_vector.at(i).Gate_name << " when fault is: " << Output_vector.at(i).value <<endl;
			}
/*			if(is_identical(Fault_free_gate_container, Fault_gate_container, Output_vector) == false)
			{
				cout << "Found!!!" <<endl;
			}*/

			Following_faults_are_detected_at(graph, gate_counter, Fault_free_gate_container, Fault_gate_container, Output_vector, Fault_vector[i], is_identical(Fault_free_gate_container, Fault_gate_container, Output_vector));
			Fault_gate_container.clear();

		}








		return 0;


	}