package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

func main() {
	// err := createApiKeys()
	// if err != nil {
	// 	fmt.Println(err)
	// }
	err := setAccessControl()
	if err != nil {
		fmt.Println(err)
	}
}
func createApiKeys() error {

	//
	// get api keys
	//

	// curl -v -X POST -H 'Accept: application/json' \
	// -H 'Content-Type: application/json' \
	// -d '{
	//     "accountId":"1a5",
	//     "publicValue":"publicKey",
	//     "secretValue":"secretKey"
	// }' \
	// http://18.194.5.24:8080/v1/projects/1a5/apikeys

	requestUrl := "http://18.194.5.24:8080/v1/projects/1a5/apikeys"
	headers := map[string]interface{}{
		"Accept":       "application/json",
		"Content-Type": "application/json",
	}

	log.Printf("[INFO] making API request: %s", requestUrl)

	client := &http.Client{}

	requestBody := `
	{
		"accountId":"1a5",
		"publicValue":"publicKey",
		"secretValue":"secretKey"
	}
	`

	req, err := http.NewRequest("POST", requestUrl, bytes.NewBufferString(requestBody))
	if err != nil {
		return fmt.Errorf("Error creating request: %s", err)
	}

	for name, value := range headers {
		req.Header.Set(name, value.(string))
	}

	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("Error during making a request: %s", requestUrl)
	}
	log.Printf("[INFO] response status code: %d", resp.StatusCode)

	if resp.StatusCode != 201 {
		return fmt.Errorf("HTTP request error. Response code: %d", resp.StatusCode)
	}

	bodyBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("ioutil.ReadAll() failed: %s", err)
	}
	log.Printf("[INFO] bodyBytes: %s", string(bodyBytes))

	body := struct {
		PubliValue  string `json:"publicValue"`
		SecretValue string `json:"secretValue"`
	}{}
	err = json.Unmarshal(bodyBytes, &body)
	if err != nil {
		return fmt.Errorf("json.Unmarshal() failed: %s", err)
	}

	if body.PubliValue == "" && body.SecretValue == "" {
		return fmt.Errorf("HTTP response body did not contain values for 'publicValue' and 'secretValue', body:\n%s", string(bodyBytes))
	}

	log.Printf("[INFO] rancher_access_key: %s", body.PubliValue)
	log.Printf("[INFO] rancher_secret_key: %s", body.SecretValue)

	resp.Body.Close()

	return nil
}

func setAccessControl() error {
	//
	// set access control
	//

	// curl -v -X POST -H 'Accept: application/json' \
	// -H 'Content-Type: application/json' \
	// -d '{
	//     "accessMode":"unrestricted",
	//     "enabled":true,
	//     "name":"admin",
	//     "username":"florian",
	//     "password":"boehmak"
	// }' \
	// http://18.194.5.24:8080/v1/localauthconfig

	requestUrl := "http://18.194.5.24:8080/v1/localauthconfig"
	username := "florian"
	password := "boehmak"
	// requestUrl := fmt.Sprintf("%s/v1/localauthconfig", d.Get("rancher_server_url").(string))
	// username := d.Get("username").(string)
	// password := d.Get("password").(string)

	headers := map[string]interface{}{
		"Accept":       "application/json",
		"Content-Type": "application/json",
	}

	log.Printf("[INFO] making API request: %s", requestUrl)

	client := &http.Client{}

	requestBody := fmt.Sprintf(`
	{
		"accessMode":"unrestricted",
		"enabled":true,
		"name":"admin",
		"username":"%s",
		"password":"%s"
	}`, username, password)
	log.Printf("[INFO] request body: %s", requestBody)

	req, err := http.NewRequest("POST", requestUrl, bytes.NewBufferString(requestBody))
	if err != nil {
		return fmt.Errorf("Error creating request: %s", err)
	}

	for name, value := range headers {
		req.Header.Set(name, value.(string))
	}

	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("Error during making a request: %s", requestUrl)
	}
	log.Printf("[INFO] response status code: %d", resp.StatusCode)

	bodyBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("ioutil.ReadAll() failed: %s", err)
	}

	if resp.StatusCode != 201 {
		return fmt.Errorf("HTTP request error. Response code: %d Response body: %s", resp.StatusCode, string(bodyBytes))
	}

	log.Printf("[INFO] Access Control created, bodyBytes: %s", string(bodyBytes))

	return nil
}
