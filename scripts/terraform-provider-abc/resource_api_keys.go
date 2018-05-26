package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"time"

	"github.com/hashicorp/terraform/helper/schema"
)

func resourceApiKeys() *schema.Resource {
	return &schema.Resource{
		Create: resourceApiKeysCreate,
		Read:   resourceApiKeysRead,
		Update: resourceApiKeysUpdate,
		Delete: resourceApiKeysDelete,

		Schema: map[string]*schema.Schema{
			"rancher_access_key": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},
			"rancher_secret_key": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},
			"rancher_server_url": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},
		},
	}
}

func resourceApiKeysCreate(d *schema.ResourceData, m interface{}) error {

	err := waitRancherAPIAvailable(d.Get("rancher_server_url").(string))
	if err != nil {
		return err
	}

	//
	// get api keys
	//

	requestUrl := fmt.Sprintf("%s/v1/projects/1a5/apikeys", d.Get("rancher_server_url").(string))
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
		return fmt.Errorf("Error during making a request: %s", err)
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

	d.Set("rancher_access_key", body.PubliValue)
	d.Set("rancher_secret_key", body.SecretValue)

	d.SetId(time.Now().UTC().String())

	return nil
}

func resourceApiKeysRead(d *schema.ResourceData, m interface{}) error {
	return nil
}

func resourceApiKeysUpdate(d *schema.ResourceData, m interface{}) error {
	return nil
}

func resourceApiKeysDelete(d *schema.ResourceData, m interface{}) error {
	return nil
}
