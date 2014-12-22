psql $DBNAME -c "
COPY (
 SELECT hsi.relation_id
      , s.sentence_id
      , description
      , is_true
      , s.words
      , p1.start_position AS p1_start
      , p1.length AS p1_length
      , p2.start_position AS p2_start
      , p2.length AS p2_length
      , p2.length AS p2_length
      -- also include all relevant features with weights
      , features[1:6] -- top 6 features with weights
      , weights[1:6]
   FROM has_spouse hsi
      , sentences s
      , people_mentions p1
      , people_mentions p2
      , ( -- find features relevant TO the relation
         SELECT relation_id
              , ARRAY_AGG(feature ORDER BY abs(weight) DESC) AS features
              , ARRAY_AGG(weight  ORDER BY abs(weight) DESC) AS weights
           FROM has_spouse_features f
              , dd_inference_result_variables_mapped_weights wm
          WHERE wm.description = ('f_has_spouse_features-' || f.feature)
          GROUP BY relation_id
        ) f
  WHERE s.sentence_id  = hsi.sentence_id
    AND p1.mention_id  = hsi.person1_id
    AND p2.mention_id  = hsi.person2_id
    AND f.relation_id  = hsi.relation_id
    AND hsi.is_true    = true
  ORDER BY random() LIMIT 100
) TO STDOUT WITH CSV HEADER;
" > supervision/has_spouse_true.csv

psql $DBNAME -c "
COPY (
 SELECT hsi.relation_id
      , s.sentence_id
      , description
      , is_true
      , s.words
      , p1.start_position AS p1_start
      , p1.length AS p1_length
      , p2.start_position AS p2_start
      , p2.length AS p2_length
      , p2.length AS p2_length
      -- also include all relevant features with weights
      , features[1:6] -- top 6 features with weights
      , weights[1:6]
   FROM has_spouse hsi
      , sentences s
      , people_mentions p1
      , people_mentions p2
      , ( -- find features relevant TO the relation
         SELECT relation_id
              , ARRAY_AGG(feature ORDER BY abs(weight) DESC) AS features
              , ARRAY_AGG(weight  ORDER BY abs(weight) DESC) AS weights
           FROM has_spouse_features f
              , dd_inference_result_variables_mapped_weights wm
          WHERE wm.description = ('f_has_spouse_features-' || f.feature)
          GROUP BY relation_id
        ) f
  WHERE s.sentence_id  = hsi.sentence_id
    AND p1.mention_id  = hsi.person1_id
    AND p2.mention_id  = hsi.person2_id
    AND f.relation_id  = hsi.relation_id
    AND hsi.is_true    = false
  ORDER BY random() LIMIT 100
) TO STDOUT WITH CSV HEADER;
" > supervision/has_spouse_false.csv