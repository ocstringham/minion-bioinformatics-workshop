# function to convert MIDORI fasta file into a CRABS formatted txt file
# assumes taxonomy supplied by MIDORI is correct
convert_midori_to_crabs() {

    input_file=$1
    output_file=$2

    awk 'BEGIN {FS=";"} 
        # Process header lines (lines starting with ">")
        /^>/ {

            # If we already have sequence and header info, print it out
            if (seq != "") {
                print id "\t" species "\t" species_taxid "\t" superkingdom "\t" phylum "\t" class "\t" order "\t" family "\t" genus "\t" species "\t" seq
            }

            # Extract ID (value after ">")
            split($0, header_parts, " ")
            id_full = header_parts[1]
            ## get rid of version number
            split(id_full, id_parts, ".")
            ## rid of the > 
            split(id_parts[1], id_parts2, ">")
            id = id_parts2[2]

            # Initialize variables for taxonomy info
            species = ""
            species_taxid = ""
            genus = ""
            family = ""
            order = ""
            class = ""
            phylum = ""
            superkingdom = ""

            # Find the species part and other taxonomy information
            for (i=1; i<=NF; i++) {
                if ($i ~ /^species_/) {
                    # Split the species part by "_" to get species
                    split($i, species_parts, "_")
                    # Take the last element to get the taxid
                    species_taxid = species_parts[length(species_parts)]
                    
                    # Concatenate all parts except the first ('species') and last (taxid)
                    species = ""
                    for (j=2; j<length(species_parts); j++) {
                        if (species != "") {
                            species = species "_" species_parts[j]
                        } else {
                            species = species_parts[j]
                        }
                    }
                }
                if ($i ~ /^genus_/) {
                    split($i, genus_parts, "_")
                    genus = genus_parts[2]
                }
                if ($i ~ /^family_/) {
                    split($i, family_parts, "_")
                    family = family_parts[2]
                }
                if ($i ~ /^order_/) {
                    split($i, order_parts, "_")
                    order = order_parts[2]
                }
                if ($i ~ /^class_/) {
                    split($i, class_parts, "_")
                    class = class_parts[2]
                }
                if ($i ~ /^phylum_/) {
                    split($i, phylum_parts, "_")
                    phylum = phylum_parts[2]
                }
                if ($i ~ /^superkingdom_/) {
                    split($i, superkingdom_parts, "_")
                    superkingdom = superkingdom_parts[2]
                }
            }
            
            # Initialize the sequence variable for this header
            seq = ""
        }

        # Process sequence lines (lines not starting with ">")
        /^[^>]/ {
            # Concatenate the sequence lines to the seq variable
            seq = seq $0
        }

        # Once we have accumulated the sequence and header info, print it out
        END {
            if (seq != "") {
                print id "\t" species "\t" species_taxid "\t" superkingdom "\t" phylum "\t" class "\t" order "\t" family "\t" genus "\t" species "\t" seq
            } 
    }' "$input_file" > "$output_file"

}