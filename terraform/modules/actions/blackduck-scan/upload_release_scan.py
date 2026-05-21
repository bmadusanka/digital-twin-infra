import json
import os
import sys

import requests
import base64
from datetime import datetime

confluence_base_url = "https://devstack.vwgroup.com/confluence/rest/api/content"


def create_basic(username, token):
    basic_credentials = username + ":" + token
    utf_bytes = basic_credentials.encode("utf-8")

    base64_bytes = base64.b64encode(utf_bytes)
    return base64_bytes.decode("utf-8")


def construct_header_json(basic):
    return {
        "Authorization": f"Basic {basic}",
        "Content-Type": "application/json",
    }


def get_general_page_info(username, token, base_url, page_number):
    url = base_url + "/" + str(page_number) + "/"
    headers = construct_header_json(create_basic(username, token))
    response = requests.get(url=url, headers=headers, verify=True)
    if response.status_code != 200:
        raise Exception(str(response.status_code) + " " + response.text)
    return json.loads(response.text)


def get_current_page_content(username, token, base_url, page_number):
    url = base_url + "/" + str(page_number) + "?expand=body.storage"
    headers = construct_header_json(create_basic(username, token))
    response = requests.get(url=url, headers=headers, verify=True)
    if response.status_code != 200:
        raise Exception(str(response.status_code) + " " + response.text)
    return json.loads(response.text)


def get_page_children(username, token, base_url, page_number):
    url = base_url + "/" + str(page_number) + "/child/page"
    headers = construct_header_json(create_basic(username, token))
    response = requests.get(url=url, headers=headers, verify=True)
    if response.status_code != 200:
        raise Exception(str(response.status_code) + " " + response.text)
    return json.loads(response.text)


def create_page(username, token, base_url, parent_page_id, page_content, title, space):
    page = {
        "type": "page",
        "title": title,
        "ancestors": [{"id": str(parent_page_id)}],
        "space": {"key": space},
        "body": {"storage": {"value": page_content, "representation": "storage"}},
    }

    url = base_url
    headers = construct_header_json(create_basic(username, token))
    response = requests.post(
        url=url, data=json.dumps(page), headers=headers, verify=True
    )
    if response.status_code != 200:
        raise Exception(str(response.status_code) + " " + response.text)
    return json.loads(response.text)


def update_page(
    username, token, base_url, page_id, page_content, title, version, space
):
    page = {
        "id": page_id,
        "type": "page",
        "title": title,
        "space": {"key": space},
        "body": {"storage": {"value": page_content, "representation": "storage"}},
        "version": {"number": version},
    }
    url = base_url + "/" + str(page_id) + "/"
    headers = construct_header_json(create_basic(username, token))
    response = requests.put(
        url=url, data=json.dumps(page), headers=headers, verify=True
    )
    if response.status_code != 200:
        raise Exception(str(response.status_code) + " " + response.text)
    return json.loads(response.text)


def upload_attachment(
    username, token, base_url, page_id, file_path, new_file_name, comment
):

    url = base_url + "/" + page_id + "/child/attachment"
    # Search for existing attachment in confluence page
    search_url = (
        base_url + "/" + page_id + "/child/attachment?filename=" + new_file_name
    )
    headers = construct_header_json(create_basic(username, token))
    headers.pop("Content-Type")
    headers["X-Atlassian-Token"] = "nocheck"

    payload = {"comment": comment}
    files = [
        ("file", (new_file_name, open(file_path, "rb"), "application/octet-stream"))
    ]

    search_response = requests.get(url=search_url, headers=headers, verify=True)
    search_response_json = search_response.json()
    if len(search_response_json["results"]) == 0:
        response = requests.post(
            url=url, data=payload, files=files, headers=headers, verify=True
        )
        if response.status_code != 200:
            raise Exception(str(response.status_code) + " " + response.text)
        return json.loads(response.text)
    else:
        attachment_id = search_response_json["results"][0]["id"]
        print("Attachment ID is: ", attachment_id)
        update_payload = {"comment": comment, "minorEdit": True}
        url_attachment = (
            base_url + "/" + page_id + "/child/attachment/" + attachment_id + "/data"
        )
        update_response = requests.post(
            url=url_attachment,
            data=update_payload,
            files=files,
            headers=headers,
            verify=True,
        )
        if update_response.status_code != 200:
            raise Exception(
                str(update_response.status_code) + " " + update_response.text
            )
        return json.loads(update_response.text)


def upload_logic(
    username,
    token,
    parent_page_id,
    release_version,
    repo_name,
    paths,
    scan_prefix,
    space,
):
    page_title = str(repo_name) + "_" + str(release_version)

    # check if release page for this month exists
    print("check for existing pages")
    result = get_page_children(username, token, confluence_base_url, parent_page_id)
    upload_page = None
    for page in result["results"]:
        if page["title"] == page_title:
            upload_page = page
            print("page " + page_title + " found")
    # if not existing create page
    if upload_page is None:
        print("no page with " + page_title + " found")
        print("creating page " + page_title)
        upload_page = create_page(
            username,
            token,
            confluence_base_url,
            parent_page_id,
            "<h1>Scans</h1>"
            "<d>This page contains all BlackDuck scan runs for this project.</d>"
            "<p><ac:structured-macro "
            'ac:macro-id="3a7bd212-b31e-4deb-8444-b37af951ee62" ac:name="attachments"'
            ' ac:schema-version="1"/>'
            "</p>",
            page_title,
            space,
        )
    # upload files to page
    upload__file_names = []
    for path in paths:
        basename = os.path.basename(path)
        file_name = os.path.splitext(basename)[0]
        file_type = os.path.splitext(basename)[1]
        new_filename = f"{file_name}-{release_version}-{scan_prefix}{file_type}"
        upload__file_names.append(new_filename)
        print(
            "uploading files to page " + upload_page["title"] + " " + upload_page["id"]
        )
        upload_attachment(
            username,
            token,
            confluence_base_url,
            upload_page["id"],
            path,
            new_filename,
            "release of " + file_name,
        )
    # # show attachment on page
    # headline = repo_name + "-" + release_version + "-" + scan_prefix
    # page_with_content = get_current_page_content(
    #     username, token, confluence_base_url, upload_page["id"]
    # )
    # page_content = page_with_content["body"]["storage"]["value"]
    # page_content += f"<h3>{headline}</h3>"
    # for file_name in upload__file_names:
    #     page_content += (
    #         f'<p><ac:link><ri:attachment ri:filename="{file_name}"/></ac:link></p>'
    #     )

    # page_info = get_general_page_info(
    #     username, token, confluence_base_url, upload_page["id"]
    # )
    # print("updating page")
    # update_page(
    #     username,
    #     token,
    #     confluence_base_url,
    #     upload_page["id"],
    #     page_content,
    #     page_title,
    #     page_info["version"]["number"] + 1,
    #     space,
    # )


if __name__ == "__main__":
    arguments = sys.argv

    username = arguments[1]
    token = arguments[2]
    parent_page_id = arguments[3]
    release_version = arguments[4]
    repo_name = arguments[5]
    space = arguments[6]
    scan_prefix = arguments[7]
    paths = arguments[8 : len(arguments)]

    print(
        "received following params",
        username,
        parent_page_id,
        release_version,
        repo_name,
        space,
        scan_prefix,
        paths,
    )

    upload_logic(
        username,
        token,
        parent_page_id,
        release_version,
        repo_name,
        paths,
        scan_prefix,
        space,
    )
