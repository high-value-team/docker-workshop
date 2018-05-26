package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"time"

	"github.com/hashicorp/terraform/helper/schema"
)

func resourceAccessControl() *schema.Resource {
	return &schema.Resource{
		Create: resourceAccessControlCreate,
		Read:   resourceAccessControlRead,
		Update: resourceAccessControlUpdate,
		Delete: resourceAccessControlDelete,

		Schema: map[string]*schema.Schema{
			"rancher_server_url": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},
			"username": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},
			"password": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},
		},
	}
}

func resourceAccessControlCreate(d *schema.ResourceData, m interface{}) error {

	err := waitRancherAPIAvailable(d.Get("rancher_server_url").(string))
	if err != nil {
		return err
	}

	//
	// set access control
	//

	requestUrl := fmt.Sprintf("%s/v1/localauthconfig", d.Get("rancher_server_url").(string))
	username := d.Get("username").(string)
	password := d.Get("password").(string)

	if username == "" || password == "" {
		return fmt.Errorf("'username' and 'password' must NOT be empty!")
	}

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
		return fmt.Errorf("Error during making a request: %s", err)
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

	d.SetId(time.Now().UTC().String())

	return nil
}

func resourceAccessControlRead(d *schema.ResourceData, m interface{}) error {
	return nil
}

func resourceAccessControlUpdate(d *schema.ResourceData, m interface{}) error {
	return nil
}

func resourceAccessControlDelete(d *schema.ResourceData, m interface{}) error {
	return nil
}

func waitRancherAPIAvailable(requestUrl string) error {
	headers := map[string]interface{}{}
	maxCount := 20
	timeout := 5 * time.Second
	for i := 0; i < maxCount; i++ {

		log.Printf("[INFO] making API request: %s", requestUrl)

		client := &http.Client{}

		req, err := http.NewRequest("GET", requestUrl, nil)
		if err != nil {
			return fmt.Errorf("Error creating request: %s", err)
		}

		for name, value := range headers {
			req.Header.Set(name, value.(string))
		}

		resp, err := client.Do(req)
		if err != nil {
			log.Printf("[INFO] Rancher API not available yet, trying again after some time, err: %s", err)
			time.Sleep(timeout)
			continue
		}
		log.Printf("[INFO] response status code: %d", resp.StatusCode)

		bodyBytes, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return fmt.Errorf("ioutil.ReadAll() failed: %s", err)
		}

		resp.Body.Close()

		if resp.StatusCode == 200 {
			break
		} else if resp.StatusCode == 401 {
			return fmt.Errorf("Cannot access Rancher API: unauthorized, body: %s", string(bodyBytes))
		}

		time.Sleep(timeout)
	}

	log.Printf("[INFO] rancher api available at: %s", requestUrl)

	return nil
}
