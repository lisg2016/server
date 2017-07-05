package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"reflect"
	"strings"

	"Server/pb/config"

	"github.com/extrame/xlsx"
)

const (
	EXCEL_DIR = "./excel/"
	LUA_DIR   = "./lua/"
	CFG_DIR   = "./cfg/"
)

type excel_cfg struct {
	Name  string
	Table string
	Keys  []string
	Multi int
}

type lua_value struct {
	Name  string
	Value interface{}
}

type lua_data struct {
	Keys   map[int]*lua_data
	Values [][]*lua_value
}

func dump_lua(data *lua_data) string {
	result := ""
	if len(data.Values) != 0 {

		for k, d := range data.Values {
			sub_r := fmt.Sprintf("[%d] = {\n", k+1)

			for _, dd := range d {

				switch ddd := dd.Value.(type) {
				case *int64:
					sub_r += fmt.Sprintf("%s = %d,\n", dd.Name, *ddd)
				case *float64:
					sub_r += fmt.Sprintf("%s = %f,\n", dd.Name, *ddd)
				case *string:
					sub_r += fmt.Sprintf("%s = \"%s\",\n", dd.Name, *ddd)

				}
			}

			sub_r += "\n},\n"
			result += sub_r
		}

	} else {
		for k, d := range data.Keys {
			sub_r := fmt.Sprintf("[%d] = {\n", k)
			sub_r += dump_lua(d)
			sub_r += "\n},\n"

			result += sub_r
		}
	}

	return result
}

func main() {

	var cfg_excel []*excel_cfg
	cfg_file_buf, err := ioutil.ReadFile("excel_cfg.json")
	if err != nil {
		panic(err)
	}

	if err = json.Unmarshal(cfg_file_buf, &cfg_excel); err != nil {
		panic(err)
	}

	conv_type := "conv"
	if len(os.Args) >= 2 {
		conv_type = os.Args[1]
	}

	fmt.Printf("start %s\n", conv_type)

	if conv_type == "proto" {
		var out_string string
		var reg_string string
		var mgr_string string
		var load_string string
		var load2_string string

		out_string += "package config\n"
		out_string += "import (\n"
		out_string += "    	\"encoding/json\"\n"
		out_string += "    	\"io/ioutil\"\n"
		out_string += ")\n"

		reg_string += "var NameToType map[string]interface{}\n"
		reg_string += "func InitRegister(){\n"
		reg_string += "    NameToType = make(map[string]interface{})\n"

		load_string += "type ConfigLoad struct {\n"

		load2_string += "func (p *ConfigLoad) Load(path string) error {\n"

		for _, cfg := range cfg_excel {
			xls_file, err := xlsx.OpenFile(EXCEL_DIR + cfg.Table)
			if err != nil {
				fmt.Printf("open %s %s\n", cfg.Table, err.Error())
				continue
			}

			field_name := []string{}
			field_type := []string{}

			xls_sheet := xls_file.Sheets[0]

			for i := 0; i < xls_sheet.MaxCol; i++ {
				xls_fieldname := xls_sheet.Cell(0, i)
				if xls_fieldname == nil {
					break
				}

				fieldname, err := xls_fieldname.String()
				if err != nil || fieldname == "" {
					break
				}
				fieldname = strings.Title(fieldname)

				field_name = append(field_name, fieldname)

				xls_fieldtype := xls_sheet.Cell(1, i)
				t := "uint32"
				if xls_fieldtype != nil {
					if fieldtype, err := xls_fieldtype.String(); err == nil && fieldtype != "" {
						t = fieldtype
					}
				}

				field_type = append(field_type, t)
			}

			if len(field_name) == 0 {
				continue
			}

			out_string += "type " + cfg.Name + " struct {\n"
			for i, fieldname := range field_name {
				out_string += "    " + fieldname + " " + field_type[i] + "\n"
			}
			out_string += "}\n\n"

			reg_string += "    NameToType[\"" + cfg.Name + "\"] = new(" + cfg.Name + ")\n"

			mgr_template := ` 
type %sManager struct { 
    Data map[uint64]%s 
} 
 
func (p *%sManager) Init(data []%s) { 
    p.Data = make(map[uint64]%s)
	for _, d := range data { 
		key := uint64(d.%s) 
        if %s == 1 { 
		    key = uint64(d.%s) << 32 | key 
		} 
		 
		%s
	} 
} 
 
func (p *%sManager) Get(k ...uint32) %s { 
	key := uint64(k[0]) 
	if len(k) > 1 { 
		key = uint64(k[1])<<32 | key 
	} 
 
	result, _ := p.Data[key] 
	return result 
} 

`

			type_name := cfg.Name
			data_name := "*" + cfg.Name
			result_name := "*" + cfg.Name
			if cfg.Multi != 0 {
				result_name = "[]*" + cfg.Name
			}
			key1 := "Id"
			if len(cfg.Keys) > 0 {
				key1 = cfg.Keys[0]
			}
			key2 := key1
			multi_key := "0"
			if len(cfg.Keys) > 1 {
				multi_key = "1"
				key2 = cfg.Keys[1]
			}
			insert_value := "p.Data[key] = d"
			if cfg.Multi != 0 {
				insert_value = "p.Data[key] = append(p.Data[key], d)"
			}

			mgr_string += fmt.Sprintf(mgr_template, type_name, result_name, type_name, data_name, result_name, key1, multi_key, key2, insert_value, type_name, result_name)

			load_string += fmt.Sprintf("    %sData []*%s\n", type_name, type_name)
			load_string += fmt.Sprintf("    %sMgr %sManager\n\n", type_name, type_name)

			load2_string += fmt.Sprintf(`
    cfg_%s_buf, err := ioutil.ReadFile(path + "%s.cfg")
    if err != nil {
		return err
	}
	if err = json.Unmarshal(cfg_%s_buf, &p.%sData); err != nil {
		return err
	}
	p.%sMgr.Init(p.%sData)
`, type_name, type_name, type_name, type_name, type_name, type_name)

		}

		load_string += "}\n\n"
		load2_string += "    return nil\n"
		load2_string += "}\n\n"

		reg_string += "}\n\n"
		out_string += reg_string
		out_string += mgr_string
		out_string += load_string
		out_string += load2_string

		ioutil.WriteFile("config.go", []byte(out_string), os.ModeAppend)

		//fmt.Printf("%s\n", out_string)
	}

	if conv_type == "conv" {
		config.InitRegister()

		for _, cfg := range cfg_excel {
			xls_file, err := xlsx.OpenFile(EXCEL_DIR + cfg.Table)
			if err != nil {
				fmt.Printf("open %s %s\n", cfg.Table, err.Error())
				continue
			}

			cfg_type, ok := config.NameToType[cfg.Name]
			if !ok {
				continue
			}

			var cfg_table []interface{}

			xls_sheet := xls_file.Sheets[0]

			field_name := []string{}
			for i := 0; i < xls_sheet.MaxCol; i++ {
				xls_fieldname := xls_sheet.Cell(0, i)
				if xls_fieldname == nil {
					break
				}

				fieldname, err := xls_fieldname.String()
				if err != nil || fieldname == "" {
					break
				}
				fieldname = strings.Title(fieldname)

				field_name = append(field_name, fieldname)
			}

			for r := 4; r < xls_sheet.MaxRow; r++ {
				xls_cell := xls_sheet.Cell(r, 0)
				if xls_cell == nil || xls_cell.Type() == xlsx.CellTypeError {
					continue
				}
				if s, _ := xls_cell.String(); s == "" {
					continue
				}

				record_data := reflect.New(reflect.TypeOf(cfg_type).Elem()).Interface()

				for c := 0; c < xls_sheet.MaxCol && c < len(field_name); c++ {
					xls_cell := xls_sheet.Cell(r, c)
					if xls_cell == nil || xls_cell.Type() == xlsx.CellTypeError {
						continue
					}
					if s, _ := xls_cell.String(); s == "" {
						continue
					}

					fname := field_name[c]

					ref_data := reflect.ValueOf(record_data).Elem()
					ref_field := ref_data.FieldByName(fname)

					/*fmt.Print(ref_data.Type())
					fmt.Print(ref_field.Kind())
					fmt.Printf("%s\n", fname)*/

					switch ref_field.Kind() {
					case reflect.Int:
						var value int64
						value, _ = xls_cell.Int64()
						ref_field.SetInt(value)
					case reflect.Uint32:
						var value int64
						value, _ = xls_cell.Int64()
						ref_field.SetUint(uint64(value))
					case reflect.Float32:
						var value float64
						value, _ = xls_cell.Float()
						ref_field.SetFloat(value)
					case reflect.String:
						var value string
						value, _ = xls_cell.String()
						ref_field.SetString(value)
					}

				}

				cfg_table = append(cfg_table, record_data)

			}

			out_data, _ := json.MarshalIndent(cfg_table, "", " ")
			//fmt.Printf("%s\n", out_data)
			ioutil.WriteFile(CFG_DIR+cfg.Name+".cfg", []byte(out_data), os.ModeAppend)
		}
	}

	if conv_type == "lua" {

		for _, cfg := range cfg_excel {
			xls_file, err := xlsx.OpenFile(EXCEL_DIR + cfg.Table)
			if err != nil {
				fmt.Printf("open %s %s\n", cfg.Table, err.Error())
				continue
			}

			field_name := []string{}
			field_type := []string{}

			xls_sheet := xls_file.Sheets[0]

			for i := 0; i < xls_sheet.MaxCol; i++ {
				xls_fieldname := xls_sheet.Cell(0, i)
				if xls_fieldname == nil {
					break
				}

				fieldname, err := xls_fieldname.String()
				if err != nil || fieldname == "" {
					break
				}
				fieldname = strings.Title(fieldname)

				field_name = append(field_name, fieldname)

				xls_fieldtype := xls_sheet.Cell(1, i)
				t := "uint32"
				if xls_fieldtype != nil {
					if fieldtype, err := xls_fieldtype.String(); err == nil && fieldtype != "" {
						t = fieldtype
					}
				}

				field_type = append(field_type, t)
			}

			if len(field_name) == 0 {
				continue
			}

			var data_root *lua_data = new(lua_data)
			data_root.Keys = make(map[int]*lua_data)

			for row := 4; row < xls_sheet.MaxRow; row++ {

            	xls_cell_t := xls_sheet.Cell(row, 0)
				if xls_cell_t == nil || xls_cell_t.Type() == xlsx.CellTypeError {
					continue
				}
				if s, _ := xls_cell_t.String(); s == "" {
					continue
				}

				lua_value_data := []*lua_value{}
				row_keys := []int{}

				for col := 0; col < len(field_name); col++ {
					xls_fieldname := field_name[col]
					xls_fieldtype := field_type[col]

					cell_field := xls_sheet.Cell(row, col)

					var row_data *lua_value
					row_data = new(lua_value)
					row_data.Name = xls_fieldname

					switch xls_fieldtype {
					case "uint32":
						var d int64
						if d, err = cell_field.Int64(); err != nil {
                            d = 0
                        }
						row_data.Value = &d
						is_key := false

						for _, tkey := range cfg.Keys {
							if tkey == xls_fieldname {
								is_key = true
								break
							}
						}
						if len(cfg.Keys) == 0 && xls_fieldname == "Id" {
							is_key = true
						}

						if is_key == true {
							row_keys = append(row_keys, (int)(d))
						}
					case "float32","float64":
						var d float64
						if d, err = cell_field.Float(); err != nil {
                            d = 0.0
                        }
						row_data.Value = &d
					case "string":
						var d string
						if d, err = cell_field.String(); err != nil {
                            d = ""
                        }
						row_data.Value = &d
					}

					lua_value_data = append(lua_value_data, row_data)
				}

				var temp_data_root *lua_data = data_root
				for _, vkey := range row_keys {
					if key_root, exists := temp_data_root.Keys[vkey]; exists {
						temp_data_root = key_root
					} else {
						temp_data := new(lua_data)
						temp_data.Keys = make(map[int]*lua_data)
						temp_data_root.Keys[vkey] = temp_data
						temp_data_root = temp_data
					}
				}

				temp_data_root.Values = append(temp_data_root.Values, lua_value_data)

			}

			out_data := "return {\n" + dump_lua(data_root) + "\n}"
			ioutil.WriteFile(LUA_DIR+"config_data_"+cfg.Name+".lua", []byte(out_data), os.ModeAppend)

		}
	}

}
