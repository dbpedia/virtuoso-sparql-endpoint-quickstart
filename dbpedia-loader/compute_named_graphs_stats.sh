
echo "---->>> ASK FIRST THE LIST OF NAMED GRAPH"
get_named_graph='SPARQL SELECT DISTINCT(?graphName) WHERE {GRAPH ?graphName {?s ?p ?o } };'
resp=$(run_virtuoso_cmd "$get_named_graph");
graph_list=$(echo $resp | tr " " "\n" | grep -E "\/graph\/");

echo "---->>> COMPUTE FOR EACH GRAPH STATS"
for graph in ${graph_list[@]}; do
        echo "<$graph>"
        
        echo "---- CLASS PARTITIONS stats";
        echo "- classes";
        class_q1="SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO {<$graph> void:classPartition [void:class ?c ] . } WHERE {SELECT DISTINCT(?c) FROM <$graph>  { ?s a ?c . } };";
        run_virtuoso_cmd "$class_q1";

        echo "- nb entities per classes";
        class_q2="SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO {<$graph> void:classPartition [void:class ?class ; void:entities ?count ] . } WHERE {{ SELECT ?class (count(?instance) AS ?count) WHERE {SELECT DISTINCT ?class ?instance FROM <$graph> WHERE {?instance a ?class } } GROUP BY ?class } };";
        run_virtuoso_cmd "$class_q2";

        echo "- nb triplet per classes";
        class_q3="SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO {<$graph> void:classPartition [void:class ?c ; void:triples ?x ] . } WHERE {{ SELECT (COUNT(?p) AS ?x) ?c FROM <$graph> WHERE { ?s a ?c ; ?p ?o } GROUP BY ?c } };";
        run_virtuoso_cmd "$class_q3";

        echo "- nb prop by class";
        class_q4="SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO {<$graph> void:classPartition [void:class ?c ; void:properties ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?p) AS ?x) ?c FROM <$graph> WHERE { ?s a ?c ; ?p ?o } GROUP BY ?c } };";
        run_virtuoso_cmd "$class_q4";

        echo "- besoin d'explications";
        class_q5="SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO {<$graph> void:classPartition [void:class ?c ; void:classes ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?d) AS ?x) ?c  FROM <$graph> WHERE { ?s a ?c , ?d } GROUP BY ?c } };";
        run_virtuoso_cmd "$class_q5";

        echo "- distinct subject per classes";
        class_q6="SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO {<$graph> void:classPartition [void:class ?c ; void:distinctSubjects ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?s) AS ?x) ?c FROM <$graph> WHERE { ?s a ?c } GROUP BY ?c } };";
        run_virtuoso_cmd "$class_q6";

        echo "- distinct object per classes";
        class_q7="SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO {<$graph>  void:classPartition [void:class ?c ; void:distinctObjects ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?o) AS ?x) ?c FROM <$graph> WHERE { ?s a ?c ; ?p ?o } GROUP BY ?c } };";
        run_virtuoso_cmd "$class_q7";

        echo "- nb triples by prop";
        class_q8="SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO {<$graph> void:classPartition [void:class ?c ; void:propertyPartition [void:property ?p ; void:triples ?x ] ] . } WHERE {{ SELECT ?c (COUNT(?o) AS ?x) ?p FROM <$graph> WHERE { ?s a ?c ; ?p ?o } GROUP BY ?c ?p } };";
        run_virtuoso_cmd "$class_q8";

        echo "- nb subj distinct by prop";
        class_q9="SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO {<$graph>  void:classPartition [void:class ?c ; void:propertyPartition [void:property ?p ; void:distinctSubjects ?x ] ] . } WHERE {{ SELECT (COUNT(DISTINCT ?s) AS ?x) ?c ?p FROM <$graph>  WHERE { ?s a ?c ; ?p ?o } GROUP BY ?c ?p } };";
        run_virtuoso_cmd "$class_q9";

        echo "---- Property PARTITIONS";
        echo "-nb triples by property";
        prop_q1="SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO {<$graph> void:propertyPartition [void:property ?p ; void:triples ?x ] . } WHERE {{ SELECT (COUNT(?o) AS ?x) ?p FROM <$graph> WHERE { ?s ?p ?o } GROUP BY ?p } };";
        run_virtuoso_cmd "$prop_q1";

        echo "- nb distinct Subject by prop";
        prop_q2="SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO {<$graph> void:propertyPartition [void:property ?p ; void:distinctSubjects ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?s) AS ?x) ?p FROM <$graph> WHERE { ?s ?p ?o } GROUP BY ?p } };";
        run_virtuoso_cmd "$prop_q2";

        echo "- nb distinct Objects by prop";
        prop_q3="SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO {<$graph> void:propertyPartition [void:property ?p ; void:distinctObjects ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?o) AS ?x) ?p FROM <$graph> WHERE { ?s ?p ?o } GROUP BY ?p } };";
        run_virtuoso_cmd "$prop_q3";
done

echo ">>>>>>>>> END NAMED GRAPH STATS COMPUTATION"
